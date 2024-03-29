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
 * @param text The interchange sign text (varies based on the context; see the `maneuverSign` schema).
 * @param isRouteNumber True if the sign is a route number.
 * @param consecutiveCount The frequency of this sign element within a set a consecutive signs.
 */


data class ManeuverSignElement (

    /* The interchange sign text (varies based on the context; see the `maneuverSign` schema). */
    @Json(name = "text")
    val text: kotlin.String,

    /* True if the sign is a route number. */
    @Json(name = "is_route_number")
    val isRouteNumber: kotlin.Boolean? = null,

    /* The frequency of this sign element within a set a consecutive signs. */
    @Json(name = "consecutive_count")
    val consecutiveCount: kotlin.Int? = null

)

