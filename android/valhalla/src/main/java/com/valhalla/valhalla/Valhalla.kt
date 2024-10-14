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

class Valhalla(
    context: Context,
    config: ValhallaConfig,
    valhallaConfigManager: ValhallaConfigManager = ValhallaConfigManager(context),
    private val moshi: Moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()
) {

  private val valhallaActor: ValhallaActorProviding

  init {
    valhallaConfigManager.writeConfig(config)
    valhallaActor = ValhallaActor(valhallaConfigManager.getAbsolutePath())
  }

  /**
   * Fetch a route from Valhalla
   *
   * This function returns a sealed class with the format you designated. Currently this only
   * supports [ValhallaResponse.Json] & [ValhallaResponse.Osrm]
   *
   * @param request The valhalla json request.
   * @return The route response from valhalla.
   * @throws [ValhallaException]
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
}
