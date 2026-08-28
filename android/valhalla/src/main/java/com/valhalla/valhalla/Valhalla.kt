package com.valhalla.valhalla

import android.content.Context
import com.osrm.api.models.RouteResponse as OsrmRouteResponse
import com.squareup.moshi.JsonDataException
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import com.valhalla.api.models.DirectionsOptions
import com.valhalla.api.models.HeightRequest
import com.valhalla.api.models.HeightResponse
import com.valhalla.api.models.MapMatchRequest
import com.valhalla.api.models.MapMatchRouteResponse
import com.valhalla.api.models.MatrixRequest
import com.valhalla.api.models.MatrixResponse
import com.valhalla.api.models.RouteRequest
import com.valhalla.api.models.RouteResponse
import com.valhalla.api.models.TraceAttributesRequest
import com.valhalla.api.models.TraceAttributesResponse
import com.valhalla.config.models.ValhallaConfig
import com.valhalla.valhalla.config.ValhallaConfigManager
import java.io.Closeable
import java.io.IOException

/**
 * Main entry point for the Valhalla routing engine on Android.
 *
 * This class provides a Kotlin interface to the native Valhalla C++ routing engine. It handles
 * configuration management, JSON serialization, and routing requests.
 *
 * One instance holds one native actor, including the mmapped tile extract, for its whole lifetime.
 * Building it is expensive and happens during construction, so reuse a single instance across many
 * requests. Call [close] when done — ideally through Kotlin's `use { }` — since nothing else
 * releases the native actor.
 *
 * There are two ways in, matching iOS's `Valhalla(_:)` and `Valhalla(configPath:)`: hand it a
 * [ValhallaConfig] to write out and use, or point it at a config file already on disk.
 *
 * @see ValhallaConfig
 * @see ValhallaConfigManager
 * @see com.valhalla.valhalla.config.ValhallaConfigFactory
 * @see RouteRequest
 * @see ValhallaResponse
 */
class Valhalla
internal constructor(
    private val valhallaActor: ValhallaActorProviding,
    private val moshi: Moshi,
) : Closeable {

  /**
   * Writes [config] to the device, then builds the engine from it.
   *
   * @param context The Android context used for file system operations and configuration
   *   management.
   * @param config The Valhalla configuration specifying tile locations and routing options.
   * @param valhallaConfigManager Manages the Valhalla configuration file on the device. Defaults to
   *   a new instance, which writes to one fixed `valhalla.json` — give each instance its own
   *   [com.valhalla.valhalla.files.ValhallaFile] when more than one is alive at a time.
   * @param moshi JSON serialization adapter. Defaults to a Moshi instance with Kotlin reflection
   *   support.
   */
  @JvmOverloads
  constructor(
      context: Context,
      config: ValhallaConfig,
      valhallaConfigManager: ValhallaConfigManager = ValhallaConfigManager(context),
      moshi: Moshi = defaultMoshi(),
  ) : this(actorFor(config, valhallaConfigManager), moshi)

  /**
   * Builds the engine from a config file already on disk.
   *
   * Use this when the app ships or downloads a complete `valhalla.json` rather than building one
   * from a [ValhallaConfig]. The tile paths inside it must be absolute and correct for this
   * device; nothing here rewrites them. This is the counterpart of iOS's `Valhalla(configPath:)`.
   *
   * @param configPath Absolute path of the valhalla config JSON.
   * @param moshi JSON serialization adapter. Defaults to a Moshi instance with Kotlin reflection
   *   support.
   */
  @JvmOverloads
  constructor(
      configPath: String,
      moshi: Moshi = defaultMoshi(),
  ) : this(ValhallaActor(configPath), moshi)

  /**
   * Adapter for the error envelope the native wrapper produces for every failure:
   * `{"code": <int>, "message": "<string>"}`.
   *
   * `failOnUnknown` is what makes that envelope identifiable. It rejects any object carrying a key
   * beyond those two, and every successful Valhalla payload carries several, so a response either
   * is the envelope or is not. That matters most for the responses that look like errors: a
   * successful OSRM payload also has a top-level `code`, and an OSRM map-match reports its routes
   * under `matchings`, so no substring test can tell them apart.
   */
  private val errorAdapter = moshi.adapter(ErrorResponse::class.java).failOnUnknown()

  /**
   * Fetch a route from Valhalla.
   *
   * This function returns a sealed class with the format you designated. Currently this only
   * supports [ValhallaResponse.Json] and [ValhallaResponse.Osrm] formats.
   *
   * @param request The Valhalla routing request containing locations, costing model, and options.
   * @return The route response wrapped in a [ValhallaResponse] sealed class based on the requested
   *   format.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response.
   * @throws ValhallaException.InvalidResponse if the response JSON cannot be parsed.
   * @throws ValhallaException.NotSupported if an unsupported format (GPX or PBF) is requested.
   * @see RouteRequest
   * @see ValhallaResponse
   * @see RouteRequest.Format
   */
  fun route(request: RouteRequest): ValhallaResponse {
    when (request.format) {
      RouteRequest.Format.gpx,
      RouteRequest.Format.pbf -> throw ValhallaException.NotSupported()
      else -> Unit
    }

    val encodedRequest = moshi.adapter(RouteRequest::class.java).toJson(request)
    val rawResponse = routeRaw(encodedRequest)

    return when (request.format) {
      RouteRequest.Format.osrm ->
          ValhallaResponse.Osrm(decodeResponse(rawResponse, OsrmRouteResponse::class.java))

      // else includes default valhalla: RouteRequest.Format.json
      else -> ValhallaResponse.Json(decodeResponse(rawResponse, RouteResponse::class.java))
    }
  }

  /**
   * Map-match a GPS trace onto the road network and return a route along the matched path.
   *
   * This is Valhalla's `trace_route` action. Supply the trace either as [MapMatchRequest.shape] or
   * as a [MapMatchRequest.encodedPolyline] — note that the polyline must be encoded with six digits
   * of precision rather than the usual five.
   *
   * Everything runs against the tiles already on the device, so this works with no network.
   *
   * @param request The trace to match, the costing model, and how to match it.
   * @return The matched trip.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response, which
   *   includes the case where the trace cannot be matched to the road network.
   * @throws ValhallaException.InvalidResponse if the response JSON cannot be parsed.
   * @throws ValhallaException.NotSupported if the request asks for a format other than JSON. OSRM
   *   map-match responses report their routes under `matchings`, a shape `osrm-openapi` does not
   *   model, and GPX is not JSON at all; reach both through [traceRouteRaw]. PBF is binary and
   *   cannot cross the bridge, so it comes back as an error.
   * @see MapMatchRequest
   * @see traceAttributes
   */
  fun traceRoute(request: MapMatchRequest): MapMatchRouteResponse {
    when (request.directionsOptions?.format) {
      null,
      DirectionsOptions.Format.json -> Unit
      else -> throw ValhallaException.NotSupported()
    }

    val encodedRequest = moshi.adapter(MapMatchRequest::class.java).toJson(request)
    val rawResponse = traceRouteRaw(encodedRequest)

    return decodeResponse(rawResponse, MapMatchRouteResponse::class.java)
  }

  /**
   * Map-match a GPS trace onto the road network and return the attributes of every edge along the
   * matched path.
   *
   * This is Valhalla's `trace_attributes` action. Use it instead of [traceRoute] when you need the
   * road network itself — edge identifiers, road classes, speeds, names — rather than turn-by-turn
   * directions. Narrow the response with [TraceAttributesRequest.filters]; by default Valhalla
   * returns every attribute it has, which is a lot of JSON for a long trace.
   *
   * Everything runs against the tiles already on the device, so this works with no network.
   *
   * Unlike [traceRoute], this action always answers with Valhalla's own JSON — a `format` on the
   * request's directions options is ignored rather than rejected.
   *
   * Exclude `matched.edge_index` through [TraceAttributesRequest.filters] when matching with
   * `map_snap`. Valhalla leaves that field unpopulated for some matched points while still
   * reporting a valid edge id, so it emits the `size_t` sentinel — 18446744073709551615 — which
   * does not fit in a `Long`, and the whole response becomes undecodable rather than just that one
   * field. Tracked upstream as valhalla/valhalla#3699, with a fix proposed in
   * valhalla/valhalla#6278.
   *
   * @param request The trace to match, the costing model, and which attributes to return.
   * @return The matched edges, points, and the admins they reference.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response, which
   *   includes the case where the trace cannot be matched to the road network.
   * @throws ValhallaException.InvalidResponse if the response JSON cannot be parsed.
   * @see TraceAttributesRequest
   * @see traceRoute
   */
  fun traceAttributes(request: TraceAttributesRequest): TraceAttributesResponse {
    val encodedRequest = moshi.adapter(TraceAttributesRequest::class.java).toJson(request)
    val rawResponse = traceAttributesRaw(encodedRequest)

    return decodeResponse(rawResponse, TraceAttributesResponse::class.java)
  }

  /**
   * Sample terrain heights under a shape, from the elevation tiles in the config's
   * `additionalData.elevation`. Without them every height is null.
   *
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response.
   * @throws ValhallaException.InvalidResponse if the response JSON cannot be parsed.
   */
  fun height(request: HeightRequest): HeightResponse {
    val encodedRequest = moshi.adapter(HeightRequest::class.java).toJson(request)
    val rawResponse = heightRaw(encodedRequest)

    return decodeResponse(rawResponse, HeightResponse::class.java)
  }

  /**
   * Computes a matrix of costs and times between every source and every target.
   *
   * This is Valhalla's `sources_to_targets` action. The response reports only distance and
   * time between each source/target pair, never geometry — request [route] separately for the
   * shape of any specific connection you need to draw.
   *
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response.
   * @throws ValhallaException.InvalidResponse if the response JSON cannot be parsed.
   */
  fun matrix(request: MatrixRequest): MatrixResponse {
    val encodedRequest = moshi.adapter(MatrixRequest::class.java).toJson(request)
    val rawResponse = matrixRaw(encodedRequest)

    return decodeResponse(rawResponse, MatrixResponse::class.java)
  }

  /**
   * Run a `route` request supplied as JSON and return the raw response.
   *
   * This is the escape hatch for response formats [RouteResponse] cannot model — GPX — and for
   * request options the generated models do not yet carry. PBF is binary and cannot cross the
   * bridge, so it comes back as an error.
   *
   * @param requestJson A `route` request as JSON.
   * @return The raw response body, in whichever format the request asked for.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response.
   * @see route
   */
  fun routeRaw(requestJson: String): String {
    return checkForError(valhallaActor.route(requestJson))
  }

  /**
   * Run a `trace_route` request supplied as JSON and return the raw response.
   *
   * This is the escape hatch for response formats [MapMatchRouteResponse] cannot model, and for
   * request options the generated models do not yet carry.
   *
   * @param requestJson A `trace_route` request as JSON.
   * @return The raw response body, in whichever format the request asked for.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response.
   * @see traceRoute
   */
  fun traceRouteRaw(requestJson: String): String {
    return checkForError(valhallaActor.traceRoute(requestJson))
  }

  /**
   * Run a `trace_attributes` request supplied as JSON and return the raw response.
   *
   * @param requestJson A `trace_attributes` request as JSON.
   * @return The raw JSON response body.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response.
   * @see traceAttributes
   */
  fun traceAttributesRaw(requestJson: String): String {
    return checkForError(valhallaActor.traceAttributes(requestJson))
  }

  /** Run a `height` request supplied as JSON and return the raw response. */
  fun heightRaw(requestJson: String): String {
    return checkForError(valhallaActor.height(requestJson))
  }

  /**
   * Run a `sources_to_targets` request supplied as JSON and return the raw response.
   *
   * This is the escape hatch for request options [MatrixRequest] does not yet model, or a
   * response format [MatrixResponse] cannot represent.
   *
   * @param requestJson A `sources_to_targets` request as JSON. See
   *   https://valhalla.github.io/valhalla/api/matrix/api-reference/
   * @return The raw response body, in whichever format the request asked for.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response.
   * @see matrix
   */
  fun matrixRaw(requestJson: String): String {
    return checkForError(valhallaActor.matrix(requestJson))
  }

  /**
   * Decodes [rawResponse] into [type].
   *
   * Moshi's own failures are reported as [ValhallaException.InvalidResponse], with the parse error
   * kept as the cause. Letting a `JsonDataException` escape would break the documented contract of
   * these methods, and would leave a caller unable to tell "the engine said no" apart from "we
   * could not read what it said".
   */
  private fun <T> decodeResponse(rawResponse: String, type: Class<T>): T =
      try {
        moshi.adapter(type).fromJson(rawResponse) ?: throw ValhallaException.InvalidResponse()
      } catch (e: JsonDataException) {
        throw ValhallaException.InvalidResponse(e)
      } catch (e: IOException) {
        throw ValhallaException.InvalidResponse(e)
      }

  /**
   * Returns [rawResponse] unchanged, unless it is the native wrapper's error envelope — in which
   * case the error it carries is thrown.
   *
   * A [JsonDataException] means the response is not the envelope, because it carries other keys or
   * its `code` is not an int. An [IOException] means malformed JSON, which is left to the caller's
   * decode so the problem is reported against the shape actually expected.
   */
  private fun checkForError(rawResponse: String): String {
    val error =
        try {
          errorAdapter.fromJson(rawResponse)
        } catch (e: JsonDataException) {
          null
        } catch (e: IOException) {
          null
        }

    error?.let { throw ValhallaException.Internal(it) }
    return rawResponse
  }

  /**
   * Release the native actor held by this instance. Safe to call more than once.
   *
   * Any request attempted after this throws [IllegalStateException].
   */
  override fun close() {
    valhallaActor.close()
  }

  private companion object {

    fun defaultMoshi(): Moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()

    /**
     * Writes the config, then builds the actor from where it landed.
     *
     * Both steps happen before the constructor returns, so the file is read before another
     * instance sharing the same [ValhallaConfigManager] can overwrite it.
     */
    fun actorFor(
        config: ValhallaConfig,
        valhallaConfigManager: ValhallaConfigManager
    ): ValhallaActorProviding {
      valhallaConfigManager.writeConfig(config)
      return ValhallaActor(valhallaConfigManager.getAbsolutePath())
    }
  }
}
