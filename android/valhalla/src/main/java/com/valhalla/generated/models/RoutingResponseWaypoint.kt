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
 * @param lat The latitude of a point in the shape.
 * @param lon The longitude of a point in the shape.
 * @param type A `break` represents the start or end of a leg, and allows reversals. A `through` location is an intermediate waypoint that must be visited between `break`s, but at which reversals are not allowed. A `via` is similar to a `through` except that reversals are allowed. A `break_through` is similar to a `break` in that it can be the start/end of a leg, but does not allow reversals.
 * @param originalIndex The original index of the location (locations may be reordered for optimized routes)
 */


data class RoutingResponseWaypoint (

    /* The latitude of a point in the shape. */
    @Json(name = "lat")
    val lat: kotlin.Double,

    /* The longitude of a point in the shape. */
    @Json(name = "lon")
    val lon: kotlin.Double,

    /* A `break` represents the start or end of a leg, and allows reversals. A `through` location is an intermediate waypoint that must be visited between `break`s, but at which reversals are not allowed. A `via` is similar to a `through` except that reversals are allowed. A `break_through` is similar to a `break` in that it can be the start/end of a leg, but does not allow reversals. */
    @Json(name = "type")
    val type: RoutingResponseWaypoint.Type? = Type.`break`,

    /* The original index of the location (locations may be reordered for optimized routes) */
    @Json(name = "original_index")
    val originalIndex: kotlin.Int? = null

) {

    /**
     * A `break` represents the start or end of a leg, and allows reversals. A `through` location is an intermediate waypoint that must be visited between `break`s, but at which reversals are not allowed. A `via` is similar to a `through` except that reversals are allowed. A `break_through` is similar to a `break` in that it can be the start/end of a leg, but does not allow reversals.
     *
     * Values: `break`,through,via,breakThrough
     */
    @JsonClass(generateAdapter = false)
    enum class Type(val value: kotlin.String) {
        @Json(name = "break") `break`("break"),
        @Json(name = "through") through("through"),
        @Json(name = "via") via("via"),
        @Json(name = "break_through") breakThrough("break_through");
    }
}

