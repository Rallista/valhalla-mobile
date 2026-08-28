#include <cstddef>
#include <exception>
#include <memory>
#include <string>
#include <system_error>
#include <type_traits>
#include <utility>

#include <pthread.h>

#include <boost/property_tree/ptree.hpp>
#include <valhalla/tyr/actor.h>
#include <valhalla/baldr/rapidjson_utils.h>
#include <valhalla/loki/worker.h>
#include "valhalla_actor.h"

class TileGetterWrapper : public valhalla::baldr::tile_getter_t {
public:
  /**
   * @param http_client  client used to perform HTTP GET/HEAD tile requests;
   *                      ownership is transferred to the wrapper. May be null,
   *                      in which case requests report FAILURE.
   * @param is_gzipped  whether tiles are requested as gzip-compressed data
   */
  TileGetterWrapper(std::unique_ptr<ValhallaMobileHttpClient> http_client, bool is_gzipped): http_client(std::move(http_client)), is_gzipped(is_gzipped) {
  }

  GET_response_t get(const std::string& url,
                     const uint64_t range_offset = 0,
                     const uint64_t range_size = 0) override {
    GET_response_t result;
    if (http_client) { 
        result = http_client->get(url, range_offset, range_size);
    } else {
        result.status_ = tile_getter_t::status_code_t::FAILURE;
    }
    return result;
  }

  HEAD_response_t head(const std::string& url, header_mask_t header_mask) override {
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
  bool is_gzipped;
  std::unique_ptr<ValhallaMobileHttpClient> http_client;
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
 * Runs one actor action on a thread with a stack deep enough for the matcher, joining it
 * before returning.
 *
 * Only the actor call moves. Every JNIEnv use in main.cpp, and every Obj-C++ call in
 * ValhallaWrapper.mm, stays on the thread the platform called in on, so this needs no JNI
 * attach and no autorelease pool of its own. The call remains synchronous, and callers are
 * serialized one layer up (`synchronized` in Kotlin, `@synchronized` in Obj-C), so the
 * actor is still only ever touched by one thread at a time.
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

ValhallaActor::ValhallaActor(const std::string& config_path, ValhallaMobileHttpClient* http_client) {
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
    if (!mjolnir_config.get<std::string>("tile_url", std::string()).empty()) {
      tile_getter = std::make_unique<TileGetterWrapper>(
          std::move(http_client_owned), mjolnir_config.get<bool>("tile_url_gz", false));
    }
    graph_reader = std::make_unique<valhalla::baldr::GraphReader>(
      mjolnir_config, std::move(tile_getter)
    );
    // Setup the actor
    actor = std::make_unique<valhalla::tyr::actor_t>(config, *graph_reader, true);
}

std::string ValhallaActor::route(const std::string& request) {
    return run_on_deep_stack([&]() { return actor->route(request); });
}

std::string ValhallaActor::trace_route(const std::string& request) {
    return run_on_deep_stack([&]() { return actor->trace_route(request); });
}

std::string ValhallaActor::trace_attributes(const std::string& request) {
    return run_on_deep_stack([&]() { return actor->trace_attributes(request); });
}

std::string ValhallaActor::height(const std::string& request) {
    return run_on_deep_stack([&]() { return actor->height(request); });
}

std::string ValhallaActor::matrix(const std::string& request) {
    return run_on_deep_stack([&]() { return actor->matrix(request); });
}
