#include <boost/property_tree/ptree.hpp>
#include <valhalla/tyr/actor.h>
#include <valhalla/baldr/rapidjson_utils.h>
#include <valhalla/loki/worker.h>
#include "valhalla_actor.h"

ValhallaActor::ValhallaActor(const std::string& config_path): actor([&config_path]() {
    // Get the config path
    std::string config_file(config_path);
    
    // Set up the config object
    boost::property_tree::ptree config;
    rapidjson::read_json(config_file, config);
    
    // Setup the actor
    return valhalla::tyr::actor_t(config);
}()) // IIFE to prepare actor
{}

std::string ValhallaActor::route(const std::string& request) {
    // Convert the request to a std::string
    std::string req = std::string(request);
    
    // Produce the route result
    std::string result = actor.route(req);
    
    return result;
}
