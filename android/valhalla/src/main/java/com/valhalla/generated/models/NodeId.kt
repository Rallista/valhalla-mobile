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
 * @param id 
 * @param `value` 
 * @param tileId 
 * @param level 
 */


data class NodeId (

    @Json(name = "id")
    val id: kotlin.Long? = null,

    @Json(name = "value")
    val `value`: kotlin.Long? = null,

    @Json(name = "tile_id")
    val tileId: kotlin.Long? = null,

    @Json(name = "level")
    val level: kotlin.Int? = null

)

