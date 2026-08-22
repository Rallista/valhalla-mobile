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
 * @param context The Android context used for file system operations and configuration management.
 * @param config The Valhalla configuration specifying tile locations and routing options.
 * @param valhallaConfigManager Manages the Valhalla configuration file on the device. Defaults to a
 *   new instance.
 * @param moshi JSON serialization adapter. Defaults to a Moshi instance with Kotlin reflection
 *   support.
 * @see ValhallaConfig
 * @see ValhallaConfigManager
 * @see RouteRequest
 * @see ValhallaResponse
 */
class Valhalla(
    context: Context,
    config: ValhallaConfig,
    valhallaConfigManager: ValhallaConfigManager = ValhallaConfigManager(context),
    private val moshi: Moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
) : Closeable {

  private val valhallaActor: ValhallaActorProviding

  init {
    valhallaConfigManager.writeConfig(config)
    valhallaActor = ValhallaActor(valhallaConfigManager.getAbsolutePath())
  }

  /**
   * Adapter for the error envelope the native wrapper produces for every failure:
   * `{"code": <int>, "message": "<string>"}`.
   *
   * `failOnUnknown` is what makes that envelope identifiable. It rejects any object carrying a key
   * beyond those two, and every successful Valhalla payload carries several, so a response either
   * is the envelope or is not. The substring test [route] uses cannot be reused for the trace
   * actions: a successful OSRM map-match response also has a top-level `"code"`, and it reports its
   * routes under `matchings` rather than `routes`, so it would be misread as an error.
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
   * @throws ValhallaException.InvalidError if an error response cannot be parsed.
   * @throws ValhallaException.InvalidResponse if the response JSON cannot be parsed.
   * @throws ValhallaException.NotSupported if an unsupported format (GPX or PBF) is requested.
   * @see RouteRequest
   * @see ValhallaResponse
   * @see RouteRequest.Format
   */
  fun route(request: RouteRequest): ValhallaResponse {
    val encodedRequest = moshi.adapter(RouteRequest::class.java).toJson(request)
    val rawResponse = valhallaActor.route(encodedRequest)

    // Check for error response in Valhalla format.
    // OSRM has a code and message like the valhalla error, but it's not the same format.
    // If the response contains routes, it's a valid OSRM response.
    if (rawResponse.contains("code") and !rawResponse.contains("routes")) {
      val error = moshi.adapter(ErrorResponse::class.java).fromJson(rawResponse)
      error?.let { throw ValhallaException.Internal(it) }
      throw ValhallaException.InvalidError()
    }

    return when (request.format) {
      RouteRequest.Format.gpx -> throw ValhallaException.NotSupported()
      RouteRequest.Format.osrm -> {
        val osrmResponse =
            moshi.adapter(OsrmRouteResponse::class.java).fromJson(rawResponse)
                ?: throw ValhallaException.InvalidResponse()
        ValhallaResponse.Osrm(osrmResponse)
      }

      RouteRequest.Format.pbf -> throw ValhallaException.NotSupported()
      // else includes default valhalla: RouteRequest.Format.json
      else -> {
        val valhallaResponse =
            moshi.adapter(RouteResponse::class.java).fromJson(rawResponse)
                ?: throw ValhallaException.InvalidResponse()
        ValhallaResponse.Json(valhallaResponse)
      }
    }
  }

  /**
   * Map-match a GPS trace onto the road network and return a route along the matched path.
   *
   * This is Valhalla's `trace_route` action. Supply the trace either as
   * [MapMatchRequest.shape] or as a [MapMatchRequest.encodedPolyline] — note that the polyline
   * must be encoded with six digits of precision rather than the usual five.
   *
   * Everything runs against the tiles already on the device, so this works with no network.
   *
   * @param request The trace to match, the costing model, and how to match it.
   * @return The matched trip.
   * @throws ValhallaException.Internal if the Valhalla engine returns an error response, which
   *   includes the case where the trace cannot be matched to the road network.
   * @throws ValhallaException.InvalidResponse if the response JSON cannot be parsed.
   * @throws ValhallaException.NotSupported if the request asks for a format other than JSON.
   *   OSRM map-match responses report their routes under `matchings`, a shape `osrm-openapi` does
   *   not model, and GPX and PBF are not JSON at all — reach all three through [traceRouteRaw].
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
   * `HeightResponse` cannot represent a null height or a `heightPrecision` above 0; use
   * [heightRaw] for those.
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
   * Decodes [rawResponse] into [type].
   *
   * Moshi's own failures are reported as [ValhallaException.InvalidResponse], with the parse error
   * kept as the cause. Letting a `JsonDataException` escape would break the documented contract of
   * the trace methods, and would leave a caller unable to tell "the engine said no" apart from "we
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
}
