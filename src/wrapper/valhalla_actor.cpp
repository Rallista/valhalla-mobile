#include <boost/property_tree/ptree.hpp>
#include <valhalla/tyr/actor.h>
#include <valhalla/baldr/rapidjson_utils.h>
#include <valhalla/loki/worker.h>
#include <valhalla/midgard/logging.h>
#include "valhalla_actor.h"

#ifdef __ANDROID__
#include <android/log.h>
#include <mutex>

namespace {

// Routes Valhalla's midgard::logging output to Android's logcat under tag "ValhallaNative".
// Registered with Valhalla's logger factory under the type name "android_logcat" so it can be
// selected via logging::Configure({{"type", "android_logcat"}}).
//
// Why this exists: Valhalla's default logger writes to std::clog, which on Android isn't
// attached to logcat. Internal LOG_ERROR/LOG_WARN/LOG_INFO calls inside GraphReader and Loki
// search are invisible without this bridge. With it, every internal log surfaces under
// `adb logcat -s ValhallaNative`.
class AndroidLogcatLogger : public valhalla::midgard::logging::Logger {
public:
  AndroidLogcatLogger(const valhalla::midgard::logging::LoggingConfig& config) : Logger(config) {}

  void Log(const std::string& message, const valhalla::midgard::logging::LogLevel level) override {
    std::lock_guard<std::mutex> lk(lock);
    int prio = ANDROID_LOG_INFO;
    switch (level) {
      case valhalla::midgard::logging::LogLevel::LogTrace: prio = ANDROID_LOG_VERBOSE; break;
      case valhalla::midgard::logging::LogLevel::LogDebug: prio = ANDROID_LOG_DEBUG; break;
      case valhalla::midgard::logging::LogLevel::LogInfo:  prio = ANDROID_LOG_INFO;   break;
      case valhalla::midgard::logging::LogLevel::LogWarn:  prio = ANDROID_LOG_WARN;   break;
      case valhalla::midgard::logging::LogLevel::LogError: prio = ANDROID_LOG_ERROR;  break;
    }
    __android_log_print(prio, "ValhallaNative", "%s", message.c_str());
  }

  void Log(const std::string& message, const std::string& /*custom_directive*/) override {
    std::lock_guard<std::mutex> lk(lock);
    __android_log_print(ANDROID_LOG_INFO, "ValhallaNative", "%s", message.c_str());
  }
};

valhalla::midgard::logging::Logger* CreateAndroidLogcatLogger(
    const valhalla::midgard::logging::LoggingConfig& config) {
  return new AndroidLogcatLogger(config);
}

// Registers the logger type and switches Valhalla to use it. Called once from the actor
// constructor (which is itself called once per Kotlin Valhalla instance).
void EnsureAndroidLoggerConfigured() {
  static std::once_flag flag;
  std::call_once(flag, [] {
    valhalla::midgard::logging::RegisterLogger("android_logcat", CreateAndroidLogcatLogger);
    valhalla::midgard::logging::Configure({{"type", "android_logcat"}});
    __android_log_print(ANDROID_LOG_INFO, "ValhallaNative",
                        "AndroidLogcatLogger installed; native LOG_* calls now go to logcat");
  });
}

} // namespace
#else
namespace { inline void EnsureAndroidLoggerConfigured() {} }
#endif

class TileGetterWrapper : public valhalla::baldr::tile_getter_t {
public:
  /**
   * @param pool_size  the number of curler instances in the pool
   * @param user_agent  user agent to use by curlers for HTTP requests
   * @param gzipped  whether to request for gzip compressed data
   * @param user_pw  the "user:pwd" for HTTP basic auth
   */
  TileGetterWrapper(ValhallaMobileHttpClient* http_client, bool is_gzipped): http_client(http_client), is_gzipped(is_gzipped) {
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

  ~TileGetterWrapper() {
    delete http_client;
  };

private:
  bool is_gzipped;
  ValhallaMobileHttpClient* http_client;
};


ValhallaActor::ValhallaActor(const std::string& config_path, ValhallaMobileHttpClient* http_client) {
    EnsureAndroidLoggerConfigured();

    std::string config_file(config_path);

    // Set up the config object
    boost::property_tree::ptree config;
    rapidjson::read_json(config_file, config);

    auto mjolnir_config = config.get_child("mjolnir");

    // Only wire a tile_getter when the host actually wants HTTP-based tile fetching. Passing
    // a non-null tile_getter when no http_client is supplied makes Valhalla's GraphReader
    // enter the URL-fetch fallback path on any disk-tile miss; that path calls
    // `make_single_point_url(tile_url, ...)` (in curl_tilegetter.h) which assumes the URL
    // contains a `{tilePath}` placeholder. With an empty tile_url, `substr(npos + ...)`
    // throws `std::out_of_range`, the throw propagates out of `GetGraphTile`, and Loki
    // converts it to `ValhallaError(code=171, "No suitable edges near location")`. The
    // symptom is identical whether the missing tile is a real corridor tile or an L0/admin
    // tile incidentally referenced during search/reachability — pure `mjolnir.tile_dir`
    // mode breaks unless we leave tile_getter null.
    std::unique_ptr<valhalla::baldr::tile_getter_t> tile_getter;
    if (http_client != nullptr) {
        tile_getter = std::make_unique<TileGetterWrapper>(
            http_client, mjolnir_config.get<bool>("tile_url_gz", false));
    }
    graph_reader = std::make_unique<valhalla::baldr::GraphReader>(
        mjolnir_config, std::move(tile_getter));
    // Setup the actor
    actor = std::make_unique<valhalla::tyr::actor_t>(config, *graph_reader, true);
}

std::string ValhallaActor::route(const std::string& request) {
    // Convert the request to a std::string
    std::string req = std::string(request);

    // Produce the route result
    std::string result = actor->route(req);

    return result;
}

std::string ValhallaActor::trace_attributes(const std::string& request) {
    std::string req = std::string(request);
    return actor->trace_attributes(req);
}
