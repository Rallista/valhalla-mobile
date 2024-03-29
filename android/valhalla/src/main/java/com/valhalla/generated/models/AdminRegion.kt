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
 * @param countryCode The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code.
 * @param countryText The country name
 * @param stateCode The abbreviation code for the state (varies by country).
 * @param stateText The state name.
 */


data class AdminRegion (

    /* The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code. */
    @Json(name = "country_code")
    val countryCode: kotlin.String? = null,

    /* The country name */
    @Json(name = "country_text")
    val countryText: kotlin.String? = null,

    /* The abbreviation code for the state (varies by country). */
    @Json(name = "state_code")
    val stateCode: kotlin.String? = null,

    /* The state name. */
    @Json(name = "state_text")
    val stateText: kotlin.String? = null

)

