package com.valhalla.valhalla.mapmatching

import com.squareup.moshi.Json

/**
 * Request body for Valhalla's `trace_attributes` map-matching action.
 *
 * This is the on-device equivalent of the server-side `/trace_attributes` HTTP endpoint. Pass it to
 * [com.valhalla.valhalla.Valhalla.traceAttributes] to map-match a sequence of GPS measurements
 * against the road graph and receive matched edges, lat/lng, distance-along, and other attribution.
 *
 * Field shapes follow Valhalla's map-matching API:
 * https://valhalla.github.io/valhalla/api/map-matching/api-reference/
 *
 * @property shape Ordered GPS measurements to match.
 * @property costing Costing model — `"auto"`, `"bicycle"`, `"pedestrian"`, `"motor_scooter"`, etc.
 * @property shapeMatch One of `"edge_walk"` (assume the shape is already on the graph),
 *   `"map_snap"` (run the HMM matcher), or `"walk_or_snap"` (try edge_walk first, fall back to
 *   map_snap).
 * @property filters Restrict which attributes are returned, to reduce payload size. If null,
 *   Valhalla's defaults apply.
 * @property traceOptions Tuning knobs for the HMM matcher.
 * @property costingOptions Optional costing-specific parameters, passed through to Valhalla as-is.
 * @property beginTime Epoch seconds for the first point — used when points have no `time` field but
 *   you still want consistent timing.
 * @property durations Per-point elapsed seconds since `beginTime`. Same length as `shape - 1`.
 *   Mutually exclusive with per-point `time`.
 * @property linearReferences Include OpenLR linear references in the response. Defaults to false.
 * @property bestPaths Return up to this many alternative match paths ranked by score. `1` (default)
 *   yields the single best match.
 * @property units `"kilometers"` (default) or `"miles"`.
 * @property id Echoed back in the response — useful for correlating async results in tests or logs.
 */
data class TraceAttributesRequest(
    val shape: List<TracePoint>,
    val costing: String = "auto",
    @param:Json(name = "shape_match") val shapeMatch: ShapeMatch = ShapeMatch.MAP_SNAP,
    val filters: TraceFilters? = null,
    @param:Json(name = "trace_options") val traceOptions: TraceOptions? = null,
    @param:Json(name = "costing_options") val costingOptions: Map<String, Any?>? = null,
    @param:Json(name = "begin_time") val beginTime: Double? = null,
    val durations: List<Double>? = null,
    @param:Json(name = "linear_references") val linearReferences: Boolean? = null,
    @param:Json(name = "best_paths") val bestPaths: Int? = null,
    val units: String? = null,
    val id: String? = null,
)

/**
 * A single GPS measurement.
 *
 * @property lat Latitude in WGS-84 degrees.
 * @property lon Longitude in WGS-84 degrees.
 * @property time Epoch seconds. Strongly recommended — the matcher uses temporal spacing to
 *   discount transitions over implausibly large distances.
 * @property type One of `"break"`, `"via"`, `"break_through"`, `"through"`. `"break"` marks a
 *   discontinuity (e.g., the start of a new trip leg); most navigation points should be omitted
 *   (default, `"via"`).
 * @property radius Search radius around this point in meters. Overrides the request-level
 *   `trace_options.search_radius` for this point.
 * @property heading Direction of travel in degrees clockwise from north. When present, the matcher
 *   uses it in the emission probability.
 * @property headingTolerance Allowed deviation from `heading` in degrees.
 * @property accuracy Reported GPS accuracy at this point, meters. Surfaced to the matcher as a
 *   per-point GPS-noise hint.
 */
data class TracePoint(
    val lat: Double,
    val lon: Double,
    val time: Double? = null,
    val type: String? = null,
    val radius: Double? = null,
    val heading: Double? = null,
    @param:Json(name = "heading_tolerance") val headingTolerance: Double? = null,
    val accuracy: Double? = null,
)

/**
 * Which subset of edge / point attributes the matcher should return.
 *
 * Limiting the attribute set dramatically reduces response size — a typical navigation client only
 * needs a handful of fields per matched point.
 *
 * The full list of attribute keys is documented at
 * https://valhalla.github.io/valhalla/api/map-matching/api-reference/#trace_attributes-api-results
 */
data class TraceFilters(
    val attributes: List<String>,
    val action: FilterAction = FilterAction.INCLUDE,
)

enum class FilterAction {
  @Json(name = "include") INCLUDE,
  @Json(name = "exclude") EXCLUDE,
}

enum class ShapeMatch {
  @Json(name = "edge_walk") EDGE_WALK,
  @Json(name = "map_snap") MAP_SNAP,
  @Json(name = "walk_or_snap") WALK_OR_SNAP,
}

/**
 * Tuning knobs for the HMM matcher.
 *
 * All fields are optional and default to values from the Valhalla config (typically the
 * `meili.default` and `meili.<costing>` blocks).
 *
 * @property searchRadius Meters — how far around each measurement to look for candidate edges.
 *   Increase for noisier GPS. Default: 50.
 * @property gpsAccuracy Meters — assumed GPS noise. Drives the Gaussian emission probability.
 *   Default: 5.
 * @property breakageDistance Meters — measurements separated by more than this are treated as a
 *   discontinuity. Default: 2000.
 * @property interpolationDistance Meters — points within this distance of their predecessor are
 *   flagged as `kInterpolated` rather than matched directly. Default: 10.
 * @property sigmaZ Standard deviation of GPS noise in the emission model. Default: 4.07.
 * @property beta Transition-probability scale. Higher values penalise detour-like transitions more
 *   strongly. Default: 3.
 * @property maxRouteDistanceFactor Cap on `graph_distance / haversine` for any transition.
 *   Default: 5.
 * @property maxRouteTimeFactor Cap on `graph_time / measurement_dt` for any transition. Default: 5.
 * @property turnPenaltyFactor Multiplier on turn penalties when scoring transitions.
 *   Costing-specific default (200 for auto).
 */
data class TraceOptions(
    @param:Json(name = "search_radius") val searchRadius: Double? = null,
    @param:Json(name = "gps_accuracy") val gpsAccuracy: Double? = null,
    @param:Json(name = "breakage_distance") val breakageDistance: Double? = null,
    @param:Json(name = "interpolation_distance") val interpolationDistance: Double? = null,
    @param:Json(name = "sigma_z") val sigmaZ: Double? = null,
    val beta: Double? = null,
    @param:Json(name = "max_route_distance_factor") val maxRouteDistanceFactor: Double? = null,
    @param:Json(name = "max_route_time_factor") val maxRouteTimeFactor: Double? = null,
    @param:Json(name = "turn_penalty_factor") val turnPenaltyFactor: Double? = null,
)
