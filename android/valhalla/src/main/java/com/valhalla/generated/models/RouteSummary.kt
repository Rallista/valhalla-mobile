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


import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/**
 * 
 *
 * @param time The estimated travel time, in seconds
 * @param length The estimated travel distance, in `units` (km or mi)
 * @param minLat The minimum latitude of the bounding box containing the route.
 * @param maxLat The maximum latitude of the bounding box containing the route.
 * @param minLon The minimum longitude of the bounding box containing the route.
 * @param maxLon The maximum longitude of the bounding box containing the route.
 */


data class RouteSummary (

    /* The estimated travel time, in seconds */
    @Json(name = "time")
    val time: kotlin.Double,

    /* The estimated travel distance, in `units` (km or mi) */
    @Json(name = "length")
    val length: kotlin.Double,

    /* The minimum latitude of the bounding box containing the route. */
    @Json(name = "min_lat")
    val minLat: kotlin.Double,

    /* The maximum latitude of the bounding box containing the route. */
    @Json(name = "max_lat")
    val maxLat: kotlin.Double,

    /* The minimum longitude of the bounding box containing the route. */
    @Json(name = "min_lon")
    val minLon: kotlin.Double,

    /* The maximum longitude of the bounding box containing the route. */
    @Json(name = "max_lon")
    val maxLon: kotlin.Double

)

