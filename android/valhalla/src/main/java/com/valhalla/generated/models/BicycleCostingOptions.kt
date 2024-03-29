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
 * @param maneuverPenalty A penalty (in seconds) applied when transitioning between roads (determined by name).
 * @param gateCost The estimated cost (in seconds) when a gate is encountered.
 * @param gatePenalty A penalty (in seconds) applied to the route cost when a gate is encountered. This penalty can be used to reduce the likelihood of suggesting a route with gates unless absolutely necessary.
 * @param countryCrossingCost The estimated cost (in seconds) when encountering an international border.
 * @param countryCrossingPenalty A penalty applied to transitions to international border crossings. This penalty can be used to reduce the likelihood of suggesting a route with border crossings unless absolutely necessary.
 * @param servicePenalty A penalty applied to transitions to service roads. This penalty can be used to reduce the likelihood of suggesting a route with service roads unless absolutely necessary. The default penalty is 15 for cars, busses, motor scooters, and motorcycles; and zero for others.
 * @param serviceFactor A factor that multiplies the cost when service roads are encountered. The default is 1.2 for cars and busses, and 1 for trucks, motor scooters, and motorcycles.
 * @param useLivingStreets A measure of willingness to take living streets. Values near 0 attempt to avoid them, and values near 1 will favour them. Note that as some routes may be impossible without living streets, 0 does not guarantee avoidance of them. The default value is 0 for trucks; 0.1 for other motor vehicles; 0.5 for bicycles; and 0.6 for pedestrians.
 * @param useFerry A measure of willingness to take ferries. Values near 0 attempt to avoid ferries, and values near 1 will favour them. Note that as some routes may be impossible without ferries, 0 does not guarantee avoidance of them.
 * @param bicycleType 
 * @param cyclingSpeed The average comfortable travel speed (in kph) along smooth, flat roads. The costing will vary the speed based on the surface, bicycle type, elevation change, etc. This value should be the average sustainable cruising speed the cyclist can maintain over the entire route. The default speeds are as follows based on bicycle type:   * Road - 25kph   * Cross - 20kph   * Hybrid - 18kph   * Mountain - 16kph
 * @param useRoads A measure of willingness to use roads alongside other vehicles. Values near 0 attempt to avoid roads and stay on cycleways, and values near 1 indicate the cyclist is more comfortable on roads.
 * @param useHills A measure of willingness to take tackle hills. Values near 0 attempt to avoid hills and steeper grades even if it means a longer route, and values near 1 indicates that the user does not fear them. Note that as some routes may be impossible without hills, 0 does not guarantee avoidance of them.
 * @param avoidBadSurfaces A measure of how much the cyclist wants to avoid roads with poor surfaces relative to the type of bicycle being ridden. When 0, there is no penalization of roads with poorer surfaces, and only bicycle speed is taken into account. As the value approaches 1, roads with poor surfaces relative to the bicycle type receive a heaver penalty, so they will only be taken if they significantly reduce travel time. When the value is 1, all bad surfaces are completely avoided from the route, including the start and end points.
 * @param bssReturnCost The estimated cost (in seconds) to return a bicycle in `bikeshare` mode.
 * @param bssReturnPenalty A penalty (in seconds) to return a bicycle in `bikeshare` mode.
 */


data class BicycleCostingOptions (

    /* A penalty (in seconds) applied when transitioning between roads (determined by name). */
    @Json(name = "maneuver_penalty")
    val maneuverPenalty: kotlin.Int? = 5,

    /* The estimated cost (in seconds) when a gate is encountered. */
    @Json(name = "gate_cost")
    val gateCost: kotlin.Int? = 15,

    /* A penalty (in seconds) applied to the route cost when a gate is encountered. This penalty can be used to reduce the likelihood of suggesting a route with gates unless absolutely necessary. */
    @Json(name = "gate_penalty")
    val gatePenalty: kotlin.Int? = 300,

    /* The estimated cost (in seconds) when encountering an international border. */
    @Json(name = "country_crossing_cost")
    val countryCrossingCost: kotlin.Int? = 600,

    /* A penalty applied to transitions to international border crossings. This penalty can be used to reduce the likelihood of suggesting a route with border crossings unless absolutely necessary. */
    @Json(name = "country_crossing_penalty")
    val countryCrossingPenalty: kotlin.Int? = 0,

    /* A penalty applied to transitions to service roads. This penalty can be used to reduce the likelihood of suggesting a route with service roads unless absolutely necessary. The default penalty is 15 for cars, busses, motor scooters, and motorcycles; and zero for others. */
    @Json(name = "service_penalty")
    val servicePenalty: kotlin.Int? = null,

    /* A factor that multiplies the cost when service roads are encountered. The default is 1.2 for cars and busses, and 1 for trucks, motor scooters, and motorcycles. */
    @Json(name = "service_factor")
    val serviceFactor: kotlin.Double? = 1.0,

    /* A measure of willingness to take living streets. Values near 0 attempt to avoid them, and values near 1 will favour them. Note that as some routes may be impossible without living streets, 0 does not guarantee avoidance of them. The default value is 0 for trucks; 0.1 for other motor vehicles; 0.5 for bicycles; and 0.6 for pedestrians. */
    @Json(name = "use_living_streets")
    val useLivingStreets: kotlin.Double? = null,

    /* A measure of willingness to take ferries. Values near 0 attempt to avoid ferries, and values near 1 will favour them. Note that as some routes may be impossible without ferries, 0 does not guarantee avoidance of them. */
    @Json(name = "use_ferry")
    val useFerry: kotlin.Double? = 0.5,

    @Json(name = "bicycle_type")
    val bicycleType: BicycleCostingOptions.BicycleType? = BicycleType.hybrid,

    /* The average comfortable travel speed (in kph) along smooth, flat roads. The costing will vary the speed based on the surface, bicycle type, elevation change, etc. This value should be the average sustainable cruising speed the cyclist can maintain over the entire route. The default speeds are as follows based on bicycle type:   * Road - 25kph   * Cross - 20kph   * Hybrid - 18kph   * Mountain - 16kph */
    @Json(name = "cycling_speed")
    val cyclingSpeed: kotlin.Int? = null,

    /* A measure of willingness to use roads alongside other vehicles. Values near 0 attempt to avoid roads and stay on cycleways, and values near 1 indicate the cyclist is more comfortable on roads. */
    @Json(name = "use_roads")
    val useRoads: kotlin.Double? = 0.5,

    /* A measure of willingness to take tackle hills. Values near 0 attempt to avoid hills and steeper grades even if it means a longer route, and values near 1 indicates that the user does not fear them. Note that as some routes may be impossible without hills, 0 does not guarantee avoidance of them. */
    @Json(name = "use_hills")
    val useHills: kotlin.Double? = 0.5,

    /* A measure of how much the cyclist wants to avoid roads with poor surfaces relative to the type of bicycle being ridden. When 0, there is no penalization of roads with poorer surfaces, and only bicycle speed is taken into account. As the value approaches 1, roads with poor surfaces relative to the bicycle type receive a heaver penalty, so they will only be taken if they significantly reduce travel time. When the value is 1, all bad surfaces are completely avoided from the route, including the start and end points. */
    @Json(name = "avoid_bad_surfaces")
    val avoidBadSurfaces: kotlin.Double? = 0.25,

    /* The estimated cost (in seconds) to return a bicycle in `bikeshare` mode. */
    @Json(name = "bss_return_cost")
    val bssReturnCost: kotlin.Int? = 120,

    /* A penalty (in seconds) to return a bicycle in `bikeshare` mode. */
    @Json(name = "bss_return_penalty")
    val bssReturnPenalty: kotlin.Int? = 0

) {

    /**
     * 
     *
     * Values: road,hybrid,cross,mountain
     */
    @JsonClass(generateAdapter = false)
    enum class BicycleType(val value: kotlin.String) {
        @Json(name = "Road") road("Road"),
        @Json(name = "Hybrid") hybrid("Hybrid"),
        @Json(name = "Cross") cross("Cross"),
        @Json(name = "Mountain") mountain("Mountain");
    }
}

