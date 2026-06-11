package com.valhalla.valhalla

import android.content.Context
import com.osrm.api.models.RouteResponse as OsrmRouteResponse
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import com.valhalla.api.models.DirectionsOptions
import com.valhalla.api.models.RouteRequest
import com.valhalla.api.models.RouteResponse
import com.valhalla.config.models.ValhallaConfig
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.http.ValhallaHttpClient
import com.valhalla.valhalla.mapmatching.TraceAttributesRequest
import java.io.Closeable
import java.io.File
import org.json.JSONObject

/**
 * Main entry point for the Valhalla routing engine on Android.
 *
 * This class provides a Kotlin interface to the native Valhalla C++ routing engine. It handles
 * configuration management, JSON serialization, and routing requests.
 *
 * Holds a single native ValhallaActor (and its GraphReader, including any mmap'd tile extract) for
 * the lifetime of this instance. Construction is relatively expensive; reuse one instance across
 * many requests.
 *
 * Always close the instance — preferably via Kotlin's `use { }` — to free the native actor. The
 * native memory is otherwise leaked until process death.
 *
 * @param context The Android context used for file system operations and configuration management.
 * @param config The Valhalla configuration specifying tile locations and routing options.
 * @param valhallaConfigManager Manages the Valhalla configuration file on the device. Defaults to a
 *   new instance.
 * @param moshi JSON serialization adapter. Defaults to a Moshi instance with Kotlin reflection
 *   support.
 * @param httpClient Optional HTTP client. When supplied and [tileUrl] is set, Valhalla will fetch
 *   missing tiles over HTTP via this client. Pass `null` (the default) to run purely against
 *   locally-resident tiles (e.g. a `tile_extract` tar bundled or pre-downloaded by the host
 *   application).
 * @param tileUrl Optional URL template for `mjolnir.tile_url`, e.g.
 *   `https://valhalla.example.com/tiles/{tilePath}`. Valhalla replaces `{tilePath}` with the
 *   relative path of the tile being requested. When non-null this is injected into the serialized
 *   config because the upstream `valhalla-models` `Mjolnir` class does not yet expose the field;
 *   remove once a future release adds `tile_url` / `tile_url_gz` to the data class.
 * @param tileUrlGz Whether the server serves tiles with `.gz` extension. Maps to
 *   `mjolnir.tile_url_gz`. Ignored when [tileUrl] is null.
 * @see ValhallaConfig
 * @see ValhallaConfigManager
 * @see RouteRequest
 * @see ValhallaResponse
 * @see TraceAttributesRequest
 * @see ValhallaHttpClient
 */
class Valhalla(
    context: Context,
    config: ValhallaConfig,
    valhallaConfigManager: ValhallaConfigManager = ValhallaConfigManager(context),
    private val moshi: Moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build(),
    httpClient: ValhallaHttpClient? = null,
    tileUrl: String? = null,
    tileUrlGz: Boolean = false,
) : Closeable {

  private val valhallaActor: ValhallaActorProviding

  init {
    valhallaConfigManager.writeConfig(config)
    stripEmptyMjolnirPaths(valhallaConfigManager.getAbsolutePath())
    if (tileUrl != null) {
      injectTileUrl(valhallaConfigManager.getAbsolutePath(), tileUrl, tileUrlGz)
    }
    valhallaActor = ValhallaActor(valhallaConfigManager.getAbsolutePath(), httpClient)
  }

  /**
   * Removes empty-string path entries from the `mjolnir` block of the serialized config.
   *
   * The upstream `valhalla-models-config` Mjolnir data class defaults all its path-shaped fields
   * (`tile_dir`, `tile_extract`, `traffic_extract`, `transit_dir`, `transit_feeds_dir`) to the
   * empty string `""` rather than null. Moshi serializes empty strings as-is (only nulls are
   * omitted), so a config produced by `ValhallaConfigBuilder().withTileDir(path).build()` has
   * `"tile_extract": ""` alongside the intended `"tile_dir": "/your/path"`.
   *
   * Valhalla's C++ `GraphReader` treats `pt.get_optional<std::string>("tile_extract")` as truthy
   * whenever the key is present — including the empty-string value — and attempts to open it as a
   * tar. That call throws (ENOENT on a zero-length path) and is caught, but the resulting
   * GraphReader state interacts badly with the downstream `tile_dir` read path on Android,
   * surfacing as `ValhallaError(code=171, "No suitable edges near location")` on every match call
   * even when the tile files are present at the expected paths.
   *
   * Stripping the empty entries makes `pt.get_optional` return `nullopt` for them and forces the
   * clean tile_dir-only code path. Same shape as [injectTileUrl] — read-modify-write the JSON after
   * Moshi has written it, before the actor reads it.
   */
  private fun stripEmptyMjolnirPaths(configPath: String) {
    val configFile = File(configPath)
    val rendered = JSONObject(configFile.readText())
    val mjolnir = rendered.optJSONObject("mjolnir") ?: return
    for (key in MJOLNIR_PATH_KEYS) {
      if (mjolnir.has(key) && mjolnir.optString(key, null as String?) == "") {
        mjolnir.remove(key)
      }
    }
    configFile.writeText(rendered.toString())
  }

  private fun injectTileUrl(configPath: String, tileUrl: String, tileUrlGz: Boolean) {
    val configFile = File(configPath)
    val rendered = JSONObject(configFile.readText())
    val mjolnir =
        rendered.optJSONObject("mjolnir") ?: JSONObject().also { rendered.put("mjolnir", it) }
    mjolnir.put("tile_url", tileUrl)
    mjolnir.put("tile_url_gz", tileUrlGz)
    configFile.writeText(rendered.toString())
  }

  private companion object {
    /**
     * Mjolnir keys whose Kotlin defaults are the empty string and need stripping when the host
     * didn't set them. See [stripEmptyMjolnirPaths] for context.
     */
    private val MJOLNIR_PATH_KEYS =
        listOf(
            "tile_dir",
            "tile_extract",
            "traffic_extract",
            "transit_dir",
            "transit_feeds_dir",
        )
  }

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
   * @see DirectionsOptions.Format
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

    return when (request.directionsOptions?.format) {
      DirectionsOptions.Format.gpx -> throw ValhallaException.NotSupported()
      DirectionsOptions.Format.osrm -> {
        val osrmResponse =
            moshi.adapter(OsrmRouteResponse::class.java).fromJson(rawResponse)
                ?: throw ValhallaException.InvalidResponse()
        ValhallaResponse.Osrm(osrmResponse)
      }

      DirectionsOptions.Format.pbf -> throw ValhallaException.NotSupported()
      // else includes default valhalla: DirectionsOptions.Format.json
      else -> {
        val valhallaResponse =
            moshi.adapter(RouteResponse::class.java).fromJson(rawResponse)
                ?: throw ValhallaException.InvalidResponse()
        ValhallaResponse.Json(valhallaResponse)
      }
    }
  }

  /**
   * Map-match a GPS trace against the road graph using Valhalla's Meili HMM matcher and return the
   * raw `trace_attributes` JSON response.
   *
   * The response is returned as a String to give callers maximum flexibility over parsing — the
   * trace_attributes response is large and which fields matter depends on the request's
   * `filters.attributes`. Decode the JSON with whatever model fits the consumer's needs.
   *
   * @param request The map-matching request.
   * @return Raw JSON response. The response is either a successful match (typically containing
   *   `matched_points`, `edges`, `admins`, `shape`, `units`, etc.) or an error payload `{"code": N,
   *   "message": "..."}`.
   * @throws ValhallaException.Internal if the response is a Valhalla error.
   * @throws ValhallaException.InvalidError if an error response cannot be parsed.
   */
  fun traceAttributes(request: TraceAttributesRequest): String {
    val encodedRequest = moshi.adapter(TraceAttributesRequest::class.java).toJson(request)
    return traceAttributesRaw(encodedRequest)
  }

  /**
   * Escape hatch for callers that want to construct the JSON themselves — for example to use
   * attribute keys not represented in [TraceAttributesRequest], or to forward an already-built
   * request.
   *
   * Identical error semantics to [traceAttributes].
   */
  fun traceAttributesRaw(requestJson: String): String {
    val rawResponse = valhallaActor.traceAttributes(requestJson)

    // Match the heuristic used by `route`: a response containing `"code"`
    // but not `"edges"` is a Valhalla error envelope.
    if (rawResponse.contains("\"code\"") && !rawResponse.contains("\"edges\"")) {
      val error = moshi.adapter(ErrorResponse::class.java).fromJson(rawResponse)
      error?.let { throw ValhallaException.Internal(it) }
      throw ValhallaException.InvalidError()
    }

    return rawResponse
  }

  /**
   * Release the underlying native actor. Safe to call multiple times. After close, subsequent route
   * / traceAttributes calls throw IllegalStateException.
   */
  override fun close() {
    valhallaActor.close()
  }
}
