#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <exception>
#include <limits>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <system_error>
#include <type_traits>
#include <utility>
#include <vector>

#include <pthread.h>

#include <boost/property_tree/ptree.hpp>
#include <valhalla/tyr/actor.h>
#include <valhalla/baldr/compression_utils.h>
#include <valhalla/baldr/graphtile.h>
#include <valhalla/baldr/graphtileheader.h>
#include <valhalla/baldr/rapidjson_utils.h>
#include <valhalla/loki/worker.h>
#include "valhalla_actor.h"

namespace {

constexpr int kTileGzipLevel = 1;

// A raw tile can't start with the gzip magic: 0x1f would mean hierarchy level 7.
bool has_gzip_magic(const std::vector<char>& bytes) {
    return bytes.size() >= 2 && static_cast<unsigned char>(bytes[0]) == 0x1f &&
           static_cast<unsigned char>(bytes[1]) == 0x8b;
}

// Valhalla refuses a tile whose size isn't the one its header records.
bool is_whole_tile(const std::vector<char>& bytes) {
    valhalla::baldr::GraphTileHeader header;
    if (bytes.size() < sizeof(header)) {
        return false;
    }
    std::memcpy(&header, bytes.data(), sizeof(header));
    return header.end_offset() == bytes.size();
}

// Grows `out` as valhalla's deflate fills it, and trims it once it finishes.
void grow(z_stream& s, std::vector<char>& out, size_t step) {
    const size_t size = out.size();
    if (s.total_out < size) {
        out.resize(s.total_out);
        return;
    }
    out.resize(size + step);
    s.next_out = reinterpret_cast<Bytef*>(out.data() + size);
    s.avail_out = static_cast<uInt>(step);
}

// Inflates one gzip member into `out`, which is sized from the tile header it starts with.
// A body that inflates past that size, or has bytes after the member, fails.
bool gunzip(const std::vector<char>& gzip, std::vector<char>& out) {
    using valhalla::baldr::GraphTileHeader;
    if (gzip.size() > std::numeric_limits<uInt>::max()) {
        return false;
    }
    bool fed = false;
    uInt unread = 0;
    // Fed once, so a truncated stream fails instead of reading itself again.
    auto src = [&](z_stream& s) {
        if (!fed) {
            s.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(gzip.data()));
            s.avail_in = static_cast<uInt>(gzip.size());
            fed = true;
        }
    };
    // Room for the header, then doubling from four times the body up to the size it records
    // plus one byte, so a bigger tile fills it and memory follows what actually inflates.
    auto dst = [&](z_stream& s) {
        unread = s.avail_in;
        const size_t done = out.size();
        if (s.total_out < done) {
            out.resize(s.total_out);
            return Z_NO_FLUSH;
        }
        size_t size = sizeof(GraphTileHeader);
        if (done > 0) {
            GraphTileHeader header;
            std::memcpy(&header, out.data(), sizeof(header));
            const size_t claimed = header.end_offset();
            if (done > claimed || claimed < sizeof(header) ||
                claimed >= std::numeric_limits<uInt>::max()) {
                throw std::length_error("not one whole tile");
            }
            size = std::min(claimed + 1, std::max(done * 2, gzip.size() * 4));
        }
        // resize alone can round capacity up to twice the old one.
        out.reserve(size);
        out.resize(size);
        s.next_out = reinterpret_cast<Bytef*>(out.data() + done);
        s.avail_out = static_cast<uInt>(size - done);
        return Z_NO_FLUSH;
    };
    out.clear();
    return valhalla::baldr::inflate(src, dst) && unread == 0;
}

bool gzip_tile(const std::vector<char>& plain, std::vector<char>& out) {
    auto src = [&](z_stream& s) {
        s.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(plain.data()));
        s.avail_in = static_cast<uInt>(plain.size());
        return Z_FINISH;
    };
    auto dst = [&](z_stream& s) { grow(s, out, std::max<size_t>(plain.size() / 2, 64 * 1024)); };
    return valhalla::baldr::deflate(src, dst, kTileGzipLevel, true);
}

} // namespace

class TileGetterWrapper : public valhalla::baldr::tile_getter_t {
public:
  /**
   * @param http_client  client used to perform HTTP GET/HEAD tile requests;
   *                      ownership is transferred to the wrapper. May be null,
   *                      in which case requests report FAILURE.
   * @param is_gzipped  whether valhalla stores tiles gzip-compressed
   * @param failures  counts fetches that fail other than with a 404 or 410; owned by the actor
   * @param before_fetch  run before every request once it is set, and throws to stop the
   *                      action; owned by the actor, which outlives the reader that owns this
   * @param fetch_time  the time the running action has spent in requests, which each request
   *                    adds to; owned by the actor
   */
  TileGetterWrapper(std::unique_ptr<ValhallaMobileHttpClient> http_client, bool is_gzipped,
                    std::atomic<uint32_t>* failures, const std::function<void()>* before_fetch,
                    std::atomic<std::chrono::steady_clock::rep>* fetch_time)
      : is_gzipped(is_gzipped), failures_(failures), before_fetch_(before_fetch),
        fetch_time_(fetch_time), http_client(std::move(http_client)) {
  }

  GET_response_t get(const std::string& url,
                     const uint64_t range_offset = 0,
                     const uint64_t range_size = 0) override {
    // Before the request, not after: the point is to stop paying for fetches once the
    // caller has given up, and a check that runs only afterwards still pays for this one.
    if (*before_fetch_) {
      (*before_fetch_)();
    }
    const FetchTimer timer{fetch_time_};
    GET_response_t result;
    if (!http_client) {
      result.status_ = tile_getter_t::status_code_t::FAILURE;
      return result;
    }
    // A range is a slice of a remote tar, passed through as is if it's the size asked for.
    if (range_size > 0) {
      result = http_client->get(url, range_offset, range_size, false);
      if (result.status_ != tile_getter_t::status_code_t::SUCCESS) {
        count_failure(result);
      } else if (result.bytes_.size() != range_size) {
        printf("[ValhallaActor] range of %s returned %zu bytes, not %llu\n", url.c_str(),
               result.bytes_.size(), static_cast<unsigned long long>(range_size));
        // The server ignores Range, which a retry won't change.
        result.status_ = tile_getter_t::status_code_t::FAILURE;
      }
      return result;
    }
    result = http_client->get(url, 0, 0, is_gzipped);
    if (result.status_ == tile_getter_t::status_code_t::SUCCESS) {
      const bool is_tile = validate_and_encode(url, result.bytes_);
      if (!is_tile) {
        result.status_ = tile_getter_t::status_code_t::FAILURE;
      }
    }
    if (result.status_ != tile_getter_t::status_code_t::SUCCESS) {
      count_failure(result);
    }
    return result;
  }

  HEAD_response_t head(const std::string& url, header_mask_t header_mask) override {
    if (*before_fetch_) {
      (*before_fetch_)();
    }
    const FetchTimer timer{fetch_time_};
    HEAD_response_t result;
    if (http_client) { 
        result = http_client->head(url, header_mask);
    } else {
        result.status_ = tile_getter_t::status_code_t::FAILURE;
    }
    return result;
  }

  bool gzipped() const override {
    return is_gzipped;
  }

private:
  /// Adds the time one request takes, however it returns, to the action's fetch time.
  struct FetchTimer {
    std::atomic<std::chrono::steady_clock::rep>* total;
    std::chrono::steady_clock::time_point started = std::chrono::steady_clock::now();
    ~FetchTimer() {
      total->fetch_add((std::chrono::steady_clock::now() - started).count(),
                       std::memory_order_relaxed);
    }
  };

  // Anything but a 404 or 410 may be the connection, so RetryingGraphReader lets the next action
  // retry it.
  void count_failure(const GET_response_t& result) const {
    if (result.http_code_ != 404 && result.http_code_ != 410) {
      failures_->fetch_add(1, std::memory_order_relaxed);
    }
  }

  // Valhalla caches whatever it's handed, so anything but one whole tile is rejected here.
  // A tile is then gzipped or inflated to match how valhalla stores it.
  bool validate_and_encode(const std::string& url, std::vector<char>& bytes) const {
    bool ok = true;
    if (has_gzip_magic(bytes)) {
      std::vector<char> plain;
      ok = gunzip(bytes, plain) && is_whole_tile(plain);
      if (ok && !is_gzipped) {
        bytes.swap(plain);
      }
    } else if (!is_whole_tile(bytes)) {
      ok = false;
    } else if (is_gzipped) {
      std::vector<char> gzip;
      if (!gzip_tile(bytes, gzip)) {
        printf("[ValhallaActor] could not compress tile %s\n", url.c_str());
        return false;
      }
      bytes.swap(gzip);
    }
    if (!ok) {
      printf("[ValhallaActor] tile %s is not one whole tile\n", url.c_str());
    }
    return ok;
  }

  bool is_gzipped;
  std::atomic<uint32_t>* failures_;
  const std::function<void()>* before_fetch_;
  std::atomic<std::chrono::steady_clock::rep>* fetch_time_;
  std::unique_ptr<ValhallaMobileHttpClient> http_client;
};

// GraphReader remembers every tile it failed to fetch until it's rebuilt. This one forgets
// those that failed other than with a 404 or 410 when [forget_failures] is called, so an action
// still skips them, as it would offline, but the next one retries.
class RetryingGraphReader : public valhalla::baldr::GraphReader {
public:
  RetryingGraphReader(const boost::property_tree::ptree& config,
                      std::unique_ptr<valhalla::baldr::tile_getter_t>&& tile_getter,
                      const std::atomic<uint32_t>* failures)
      : GraphReader(config, std::move(tile_getter)), failures_(failures) {
  }

  using GraphReader::GetGraphTile;

  valhalla::baldr::graph_tile_ptr GetGraphTile(const valhalla::baldr::GraphId& graphid) override {
    const auto before = failures_->load(std::memory_order_relaxed);
    auto tile = GraphReader::GetGraphTile(graphid);
    if (!tile && failures_->load(std::memory_order_relaxed) != before) {
      std::lock_guard<std::mutex> lock(_404s_lock);
      retry_.push_back(graphid.tile_base());
    }
    return tile;
  }

  void forget_failures() {
    std::lock_guard<std::mutex> lock(_404s_lock);
    for (const auto& id : retry_) {
      _404s.erase(id);
    }
    retry_.clear();
  }

private:
  const std::atomic<uint32_t>* failures_;
  std::vector<valhalla::baldr::GraphId> retry_;
};


namespace {

// Valhalla's edge-walking map matcher is recursive: `expand_from_node` in
// src/valhalla/src/thor/route_matcher.cc calls itself once per matched edge, and once
// more per hierarchy transition, with nothing bounding the depth.
// A long shape therefore needs a deep stack.
// Tracing a ~1,300 edge route overflows the ~1 MB an Android JNI worker thread or a Dart
// isolate worker gets, and the 512 KB a pthread created with default attributes gets on
// Darwin, while the identical request succeeds on the 8 MB main thread.
// Server deployments never meet this because their worker threads already start at 8 MB.
// See https://github.com/Rallista/valhalla-mobile/issues/89.
//
// 16 MB is a reservation of address space, not of memory: pages are committed only as the
// stack actually grows, and the thread is destroyed when the action returns, so nothing is
// held between calls.
constexpr size_t kActorStackSize = 16 * 1024 * 1024;

// One action to run, plus the two ways it can end.
// The action is held by reference: it outlives the thread, which is joined before
// run_on_deep_stack returns.
template <typename Action> struct ActionCall {
    Action& action;
    std::string result;
    std::exception_ptr error;
};

// The pthread entry point.
// Nothing may escape it — an exception unwinding out of a thread start routine terminates
// the process — so it is captured here and rethrown on the caller's thread.
template <typename Action> void* run_action(void* arg) {
    auto* call = static_cast<ActionCall<Action>*>(arg);
    try {
        call->result = call->action();
    } catch (...) {
        call->error = std::current_exception();
    }
    return nullptr;
}

/**
 * Runs one actor action on a thread with a 16 MB stack, joining it before returning.
 *
 * The platform entry points stay where they are: every JNIEnv use in main.cpp's JNI functions,
 * and every Obj-C++ call in ValhallaWrapper.mm, still runs on the thread the platform called in
 * on. What moves with the action is whatever Valhalla calls back out of it, which is the tile
 * getter. On Android that is JniHttpClient, which reaches the JVM from this thread, so ScopedEnv
 * attaches and detaches around each fetch; on Apple the getter brings its own @autoreleasepool,
 * so this thread needs none. The call remains synchronous, and callers are serialized one layer
 * up (`synchronized` in Kotlin, `@synchronized` in Obj-C), so the actor is still only ever
 * touched by one thread at a time.
 *
 * Anything the action throws is rethrown on the caller's thread, where the platform
 * boundary turns it into the error envelope exactly as before.
 */
template <typename Action> std::string run_on_deep_stack(Action&& action) {
    using Call = ActionCall<std::remove_reference_t<Action>>;
    // On the heap because a join that fails would leave the thread possibly still writing
    // into it; see below.
    auto call = std::unique_ptr<Call>(new Call{action, {}, nullptr});

    pthread_attr_t attr;
    int rc = pthread_attr_init(&attr);
    if (rc != 0) {
        throw std::system_error(rc, std::generic_category(), "pthread_attr_init");
    }
    rc = pthread_attr_setstacksize(&attr, kActorStackSize);
    if (rc != 0) {
        pthread_attr_destroy(&attr);
        throw std::system_error(rc, std::generic_category(), "pthread_attr_setstacksize");
    }

    pthread_t thread;
    rc = pthread_create(&thread, &attr, &run_action<std::remove_reference_t<Action>>,
                        call.get());
    pthread_attr_destroy(&attr);
    if (rc != 0) {
        // EAGAIN under memory pressure is the realistic case, and it reaches the caller as
        // the error envelope rather than as a crash.
        throw std::system_error(rc, std::generic_category(), "pthread_create");
    }

    rc = pthread_join(thread, nullptr);
    if (rc != 0) {
        // Unreachable through this path — the handle is valid, joinable, and not this
        // thread — but were it ever to happen the thread could still hold a pointer to the
        // call, so the call is deliberately leaked rather than freed underneath it.
        (void)call.release();
        throw std::system_error(rc, std::generic_category(), "pthread_join");
    }

    if (call->error) {
        std::rethrow_exception(call->error);
    }
    return std::move(call->result);
}

} // namespace

ValhallaActor::ValhallaActor(const std::string& config_path,
                             ValhallaMobileHttpClient* http_client,
                             std::atomic<bool>* cancel_flag) {
    if (cancel_flag != nullptr) {
      cancelled = cancel_flag;
    }
    // Take ownership of the client immediately so it is freed on any early
    // return or exception below, and regardless of whether a getter is attached.
    std::unique_ptr<ValhallaMobileHttpClient> http_client_owned(http_client);

    std::string config_file(config_path);

    // Set up the config object
    boost::property_tree::ptree config;
    rapidjson::read_json(config_file, config);

    auto mjolnir_config = config.get_child("mjolnir");
    // Only attach the HTTP tile-getter when a tile_url is configured. Passing a
    // getter unconditionally forces GraphReader into fetch mode, so in pure
    // loose-tile mode (tile_dir set, tile_url empty) a referenced-but-missing
    // tile attempts a remote fetch against an empty URL and throws
    // (std::exception: basic_string) instead of returning nullptr. With a null
    // getter, GraphReader::GetGraphTile returns nullptr for a missing loose tile
    // (`if (!tile_getter_) return nullptr;`) — matching upstream Valhalla, so the
    // router routes around the gap. This is what offline tile_dir consumers
    // expect (e.g. region packs that don't bundle the full tile hierarchy).
    // When no tile_url is set, http_client_owned is left to free the client at
    // scope exit (loose-tile mode needs no getter).
    std::unique_ptr<TileGetterWrapper> tile_getter;
    const auto tile_url = mjolnir_config.get<std::string>("tile_url", std::string());
    if (!tile_url.empty()) {
      const bool wants_gzip = mjolnir_config.get<bool>("tile_url_gz", false);
      const bool gzipped =
          wants_gzip &&
          tile_url.find(valhalla::baldr::GraphTile::kTilePathPattern) != std::string::npos &&
          !mjolnir_config.get<std::string>("tile_dir", std::string()).empty();
      if (wants_gzip && !gzipped) {
        printf("[ValhallaActor] tile_url_gz is ignored for a tar tile_url or without a tile_dir\n");
      }
      tile_getter = std::make_unique<TileGetterWrapper>(std::move(http_client_owned), gzipped,
                                                        &fetch_failures, &before_fetch,
                                                        &fetch_time);
    }
    graph_reader = std::make_unique<RetryingGraphReader>(
      mjolnir_config, std::move(tile_getter), &fetch_failures
    );
    // From the config, not from an API call, so a consumer configures the engine in one
    // place instead of two. It sits beside the other `mjolnir.tile_url*` keys, named the
    // way valhalla names its own. Seconds, and absent or 0 means no limit, matching every
    // other optional mjolnir key.
    tile_fetch_timeout_seconds =
        std::max(0.0, mjolnir_config.get<double>("tile_url_timeout", 0.0));

    // Set only now, so fetches the reader makes while it is built, such as a remote tar's
    // index, are never stopped. Throwing is how both stop an action.
    interrupt = [this]() {
      if (cancelled->load(std::memory_order_relaxed)) {
        record_stop(Stop::cancelled);
        throw Cancelled(kCancelledMessage);
      }
    };
    before_fetch = [this]() {
      // Cancellation first: a user who pressed stop should not wait out the deadline.
      interrupt();
      const auto budget = fetch_budget.load(std::memory_order_relaxed);
      if (budget != 0 && fetch_time.load(std::memory_order_relaxed) > budget) {
        record_stop(Stop::timed_out);
        throw TimedOut(kTimedOutMessage);
      }
    };

    // Setup the actor
    actor = std::make_unique<valhalla::tyr::actor_t>(config, *graph_reader, true);
}

void ValhallaActor::cancel() {
    cancelled->store(true, std::memory_order_relaxed);
}

void ValhallaActor::resume() {
    cancelled->store(false, std::memory_order_relaxed);
}

bool ValhallaActor::fetch_failed() const {
    return fetch_failures.load(std::memory_order_relaxed) != fetch_failures_at_arm;
}

void ValhallaActor::record_stop(Stop reason) {
    Stop none = Stop::none;
    stopped.compare_exchange_strong(none, reason, std::memory_order_relaxed);
}

std::string ValhallaActor::with_deadline(const std::function<std::string()>& action) {
    arm_deadline();
    // Checked after, not relied on to propagate. Loki catches what a tile fetch throws during
    // its search and answers 171 "No suitable edges near location" -- indistinguishable from a
    // genuinely unroutable address. A caller needs to tell "the origin is gone" from "this
    // route does not exist", so the recorded stop is what says so.
    std::string answer;
    try {
        answer = action();
    } catch (...) {
        throw_if_stopped();
        if (fetch_failed()) {
            throw std::runtime_error(kFetchFailedMessage);
        }
        throw;
    }
    throw_if_stopped();
    return answer;
}

void ValhallaActor::throw_if_stopped() const {
    // Fixed strings, and no numbers in them. A caller has to tell these two apart from a
    // genuine routing failure, and the only signal that survives the trip to Swift and Kotlin
    // is the text -- so it has to be stable, and std::to_string(double) writes "15.000000".
    // The caller configured the timeout, so it already knows the number.
    switch (stopped.load(std::memory_order_relaxed)) {
    case Stop::none:
        return;
    case Stop::timed_out:
        throw TimedOut(kTimedOutMessage);
    case Stop::cancelled:
        throw Cancelled(kCancelledMessage);
    }
}

void ValhallaActor::arm_deadline() {
    stopped.store(Stop::none, std::memory_order_relaxed);
    fetch_failures_at_arm = fetch_failures.load(std::memory_order_relaxed);
    // The reader is always a RetryingGraphReader; see the constructor.
    static_cast<RetryingGraphReader&>(*graph_reader).forget_failures();
    // Per action, not per construction: the budget is "this route may spend N seconds
    // fetching", not "this engine may spend N seconds in its lifetime".
    fetch_time.store(0, std::memory_order_relaxed);
    const auto seconds = tile_fetch_timeout_seconds;
    if (seconds <= 0) {
        fetch_budget.store(0, std::memory_order_relaxed);
    } else {
        const auto budget = std::chrono::duration_cast<std::chrono::steady_clock::duration>(
            std::chrono::duration<double>(seconds));
        fetch_budget.store(std::max<std::chrono::steady_clock::rep>(budget.count(), 1),
                           std::memory_order_relaxed);
    }
}

std::string ValhallaActor::route(const std::string& request) {
    return with_deadline([&]() {
        return run_on_deep_stack([&]() { return actor->route(request, &interrupt); });
    });
}

std::string ValhallaActor::trace_route(const std::string& request) {
    return with_deadline([&]() {
        return run_on_deep_stack([&]() { return actor->trace_route(request, &interrupt); });
    });
}

std::string ValhallaActor::trace_attributes(const std::string& request) {
    return with_deadline([&]() {
        return run_on_deep_stack([&]() { return actor->trace_attributes(request, &interrupt); });
    });
}

std::string ValhallaActor::height(const std::string& request) {
    return with_deadline([&]() {
        return run_on_deep_stack([&]() { return actor->height(request, &interrupt); });
    });
}

std::string ValhallaActor::matrix(const std::string& request) {
    return with_deadline([&]() {
        return run_on_deep_stack([&]() { return actor->matrix(request, &interrupt); });
    });
}
