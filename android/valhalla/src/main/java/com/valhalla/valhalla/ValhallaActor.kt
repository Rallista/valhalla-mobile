package com.valhalla.valhalla

internal interface ValhallaActorProviding {
  fun route(request: String): String

  fun traceRoute(request: String): String

  fun traceAttributes(request: String): String
}

/**
 * Access with raw unchecked strings to the Valhalla routing engine. This class is available, but
 * not recommended for general use.
 *
 * @property configPath
 */
internal class ValhallaActor(private val configPath: String) : ValhallaActorProviding {
  private val valhallaKotlin = ValhallaKotlin()

  /**
   * Run a route request to the Valhalla routing engine. This assumes your config path is valid,
   * tiles exist and your request string is valid.
   *
   * @param request
   * @return
   */
  override fun route(request: String): String {
    return valhallaKotlin.route(request, configPath)
  }

  /**
   * Run a `trace_route` request, map-matching a GPS trace onto the road network and returning a
   * route along the matched path. Same assumptions as [route].
   *
   * @param request
   * @return
   */
  override fun traceRoute(request: String): String {
    return valhallaKotlin.traceRoute(request, configPath)
  }

  /**
   * Run a `trace_attributes` request, map-matching a GPS trace onto the road network and returning
   * the attributes of every edge along the matched path. Same assumptions as [route].
   *
   * @param request
   * @return
   */
  override fun traceAttributes(request: String): String {
    return valhallaKotlin.traceAttributes(request, configPath)
  }
}
