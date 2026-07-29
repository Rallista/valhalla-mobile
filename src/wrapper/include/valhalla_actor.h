#ifndef VALHALLAACTOR_H
#define VALHALLAACTOR_H

#include <string>
#include <valhalla/tyr/actor.h>
#include <valhalla/baldr/tilegetter.h>

class ValhallaMobileHttpClient {
public:
    virtual ~ValhallaMobileHttpClient() = default;
    
    /**
     * Makes a synchronous GET request to fetch tile data
     * @param url the URL to fetch
     * @param range_offset optional offset for range requests
     * @param range_size optional size for range requests
     * @return GET_response_t with the response data and status
     */
    virtual valhalla::baldr::tile_getter_t::GET_response_t 
    get(const std::string& url, uint64_t range_offset = 0, uint64_t range_size = 0) = 0;
    
    /**
     * Makes a synchronous HEAD request to fetch response headers
     * @param url the URL to query
     * @param header_mask mask for which headers to retrieve
     * @return HEAD_response_t with the response headers and status
     */
    virtual valhalla::baldr::tile_getter_t::HEAD_response_t 
    head(const std::string& url, valhalla::baldr::tile_getter_t::header_mask_t header_mask) = 0;
};

class ValhallaActor {
private:
    std::unique_ptr<valhalla::tyr::actor_t> actor;
    std::unique_ptr<valhalla::baldr::GraphReader> graph_reader;
public:
    ValhallaActor(const std::string& config_path, ValhallaMobileHttpClient* http_client = nullptr);

    std::string route(const std::string& request);

    /// Map-matches a GPS trace against the road graph and returns narrative
    /// maneuvers for it. The on-device counterpart of Valhalla's
    /// /trace_route endpoint.
    std::string trace_route(const std::string& request);

    /// Map-matches a GPS trace and returns the matched edges and their
    /// attributes, rather than narrative directions. The on-device
    /// counterpart of /trace_attributes.
    std::string trace_attributes(const std::string& request);

    /// Samples terrain heights under a shape, from the elevation data the
    /// config points at. The on-device counterpart of /height.
    std::string height(const std::string& request);
};

#endif // VALHALLAACTOR_H
