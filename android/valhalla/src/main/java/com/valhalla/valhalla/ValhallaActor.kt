package com.valhalla.valhalla

interface ValhallaActorProviding {
  fun route(request: String): String
}

/**
 * Access with raw unchecked strings to the Valhalla routing engine. This class is available, but
 * not recommended for general use.
 *
 * @property configPath
 */
class ValhallaActor(private val configPath: String) : ValhallaActorProviding {
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
}
