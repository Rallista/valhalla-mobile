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

import Models.RouteLeg
import Models.RouteSummary
import Models.RoutingResponseWaypoint
import Models.ValhallaLanguages
import Models.ValhallaLongUnits

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/**
 * 
 *
 * @param status The response status code
 * @param statusMessage The response status message
 * @param units 
 * @param language 
 * @param locations 
 * @param legs 
 * @param summary 
 */


data class RouteResponseTrip (

    /* The response status code */
    @Json(name = "status")
    val status: kotlin.Int,

    /* The response status message */
    @Json(name = "status_message")
    val statusMessage: kotlin.String,

    @Json(name = "units")
    val units: ValhallaLongUnits = ValhallaLongUnits.kilometers,

    @Json(name = "language")
    val language: ValhallaLanguages = ValhallaLanguages.enMinusUS,

    @Json(name = "locations")
    val locations: kotlin.collections.List<RoutingResponseWaypoint>,

    @Json(name = "legs")
    val legs: kotlin.collections.List<RouteLeg>,

    @Json(name = "summary")
    val summary: RouteSummary

)

