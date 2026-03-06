#include <boost/property_tree/ptree.hpp>
#include <valhalla/tyr/actor.h>
#include <valhalla/baldr/rapidjson_utils.h>
#include <valhalla/loki/worker.h>
#include "valhalla_actor.h"

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
std::string config_file(config_path);
    
    // Set up the config object
    boost::property_tree::ptree config;
    rapidjson::read_json(config_file, config);

    auto mjolnir_config = config.get_child("mjolnir");
    graph_reader = std::make_unique<valhalla::baldr::GraphReader>(
      mjolnir_config, 
      std::make_unique<TileGetterWrapper>(http_client, mjolnir_config.get<bool>("tile_url_gz", false))
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
