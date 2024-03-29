/**
 *
 * Please note:
 * This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * Do not edit this file manually.
 *
 */

@file:Suppress(
    "ArrayInDataClass",
    "EnumEntryName",
    "RemoveRedundantQualifierName",
    "UnusedImport"
)

package Models

import Models.CostingModel
import Models.CostingOptions
import Models.DirectionsOptions
import Models.RoutingWaypoint

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/**
 * 
 *
 * @param locations 
 * @param costing 
 * @param id An identifier to disambiguate requests (echoed by the server).
 * @param costingOptions 
 * @param avoidLocations 
 * @param avoidPolygons One or multiple exterior rings of polygons in the form of nested JSON arrays. Roads intersecting these rings will be avoided during path finding. Open rings will be closed automatically.
 * @param directionsOptions 
 */


data class RouteRequest (

    @Json(name = "locations")
    val locations: kotlin.collections.List<RoutingWaypoint>,

    @Json(name = "costing")
    val costing: CostingModel,

    /* An identifier to disambiguate requests (echoed by the server). */
    @Json(name = "id")
    val id: kotlin.String? = null,

    @Json(name = "costing_options")
    val costingOptions: CostingOptions? = null,

    @Json(name = "avoid_locations")
    val avoidLocations: kotlin.collections.List<RoutingWaypoint>? = null,

    /* One or multiple exterior rings of polygons in the form of nested JSON arrays. Roads intersecting these rings will be avoided during path finding. Open rings will be closed automatically. */
    @Json(name = "avoid_polygons")
    val avoidPolygons: kotlin.collections.List<kotlin.collections.List<kotlin.collections.List<kotlin.Double>>>? = null,

    @Json(name = "directions_options")
    val directionsOptions: DirectionsOptions? = null

)

