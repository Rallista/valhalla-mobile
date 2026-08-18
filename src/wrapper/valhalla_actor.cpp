#include <memory>
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
    // Convert the request to a std::string
    std::string req = std::string(request);
    
    // Produce the route result
    std::string result = actor->route(req);
    
    return result;
}
