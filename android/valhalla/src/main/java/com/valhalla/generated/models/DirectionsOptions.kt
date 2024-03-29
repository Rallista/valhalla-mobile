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

import Models.DistanceUnit
import Models.ValhallaLanguages

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/**
 * 
 *
 * @param units 
 * @param language 
 * @param directionsType The level of directional narrative to include. Locations and times will always be returned, but narrative generation verbosity can be controlled with this parameter.
 */


data class DirectionsOptions (

    @Json(name = "units")
    val units: DistanceUnit? = DistanceUnit.km,

    @Json(name = "language")
    val language: ValhallaLanguages? = ValhallaLanguages.enMinusUS,

    /* The level of directional narrative to include. Locations and times will always be returned, but narrative generation verbosity can be controlled with this parameter. */
    @Json(name = "directions_type")
    val directionsType: DirectionsOptions.DirectionsType? = DirectionsType.instructions

) {

    /**
     * The level of directional narrative to include. Locations and times will always be returned, but narrative generation verbosity can be controlled with this parameter.
     *
     * Values: none,maneuvers,instructions
     */
    @JsonClass(generateAdapter = false)
    enum class DirectionsType(val value: kotlin.String) {
        @Json(name = "none") none("none"),
        @Json(name = "maneuvers") maneuvers("maneuvers"),
        @Json(name = "instructions") instructions("instructions");
    }
}

