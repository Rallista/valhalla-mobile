package com.valhalla.valhalla

import com.osrm.api.models.RouteResponse as OsrmRouteResponse
import com.valhalla.api.models.RouteResponse as ValhallaRouteResponse

sealed class ValhallaResponse {
  class Osrm(val osrmResponse: OsrmRouteResponse) : ValhallaResponse()

  class Json(val jsonResponse: ValhallaRouteResponse) : ValhallaResponse()
  // TODO: GPX & PBF?
}
