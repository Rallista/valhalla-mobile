package com.valhalla.valhalla

import com.osrm.api.models.RouteResponse as OsrmRouteResponse
import com.valhalla.api.models.RouteResponse as ValhallaRouteResponse

/**
 * Sealed class representing different response formats from the Valhalla routing engine.
 *
 * This class wraps routing responses in different formats based on the [com.valhalla.api.models.DirectionsOptions.Format]
 * specified in the request.
 *
 * @see Valhalla.route
 * @see Osrm
 * @see Json
 */
sealed class ValhallaResponse {
    /**
     * OSRM-compatible routing response format.
     *
     * This format provides compatibility with the OSRM (Open Source Routing Machine) API.
     * Use this when you need interoperability with OSRM-based systems.
     *
     * @param osrmResponse The OSRM-formatted route response.
     * @see com.osrm.api.models.RouteResponse
     */
    class Osrm(val osrmResponse: OsrmRouteResponse) : ValhallaResponse()

    /**
     * Native Valhalla JSON routing response format.
     *
     * This is the default format and provides the full feature set of Valhalla's routing capabilities.
     *
     * @param jsonResponse The Valhalla-formatted route response.
     * @see com.valhalla.api.models.RouteResponse
     */
    class Json(val jsonResponse: ValhallaRouteResponse) : ValhallaResponse()
    // TODO: GPX & PBF?
}
