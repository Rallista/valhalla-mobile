package com.valhalla.valhalla

import com.valhalla.valhalla.http.ValhallaHttpClient
import java.io.Closeable
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException

internal interface ValhallaActorProviding : Closeable {
  fun route(request: String): String

  fun traceRoute(request: String): String

  fun traceAttributes(request: String): String

  fun height(request: String): String
}

/**
 * Access with raw unchecked strings to the Valhalla routing engine. This class is available, but
 * not recommended for general use.
 *
 * Holds one native actor for the lifetime of this instance, the way iOS holds one per
 * `ValhallaWrapper`. Building it parses the config and opens the tile extract, so reuse one
 * instance across many requests rather than creating one per call. That work happens here in the
 * constructor, so the config file is read before another instance can overwrite it. A config that
 * cannot be read is not fatal: the first call retries and reports through the response envelope,
 * as it always has.
 *
 * Call [close] to release the native actor; nothing else frees it.
 *
 * @property configPath
 * @param httpClient fetches tiles when the config sets `mjolnir.tile_url`. Pass null to turn
 *   fetching off, which leaves such a config reporting every fetch as a failure.
 */
internal class ValhallaActor(
    configPath: String,
    httpClient: ValhallaHttpClient? = ValhallaHttpClient(),
) : ValhallaActorProviding {
  private val valhallaKotlin = ValhallaKotlin()
  private val lock = Any()

  /** Zero once closed. Guarded by [lock]. */
  private var handle: Long = valhallaKotlin.createActor(configPath, httpClient)

  init {
    check(handle != 0L) { "could not allocate the native Valhalla actor" }
  }

  /**
   * Run a route request to the Valhalla routing engine. This assumes your config path is valid,
   * tiles exist and your request string is valid.
   *
   * @param request
   * @return
   */
  override fun route(request: String): String = perform(request, valhallaKotlin::route)

  /**
   * Run a `trace_route` request, map-matching a GPS trace onto the road network and returning a
   * route along the matched path. Same assumptions as [route].
   *
   * @param request
   * @return
   */
  override fun traceRoute(request: String): String =
      perform(request, valhallaKotlin::traceRoute)

  /**
   * Run a `trace_attributes` request, map-matching a GPS trace onto the road network and returning
   * the attributes of every edge along the matched path. Same assumptions as [route].
   *
   * @param request
   * @return
   */
  override fun traceAttributes(request: String): String =
      perform(request, valhallaKotlin::traceAttributes)

  /** Run a `height` request to sample heights under a shape. Same assumptions as [route]. */
  override fun height(request: String): String = perform(request, valhallaKotlin::height)

  /**
   * Release the native actor. Safe to call more than once; later calls do nothing.
   *
   * Any action attempted after this throws [IllegalStateException].
   */
  override fun close() {
    synchronized(lock) {
      if (handle != 0L) {
        valhallaKotlin.deleteActor(handle)
        handle = 0L
      }
    }
  }

  /**
   * The actor is not safe to use from several threads at once, so every call is serialised here —
   * the same guarantee `@synchronized(self)` gives the iOS wrapper. Holding the lock across the
   * native call is also what keeps [close] from freeing the handle mid-request.
   */
  private fun perform(request: String, action: (Long, ByteArray) -> ByteArray): String =
      synchronized(lock) {
        check(handle != 0L) { "ValhallaActor is closed" }
        decode(action(handle, request.toByteArray()))
      }

  /**
   * The wrapper answers in UTF-8 bytes. A response that is not UTF-8, such as `format: pbf`,
   * becomes the error envelope, byte for byte the answer iOS gives in ValhallaWrapper.mm.
   */
  private fun decode(response: ByteArray): String =
      try {
        Charsets.UTF_8.newDecoder().decode(ByteBuffer.wrap(response)).toString()
      } catch (e: CharacterCodingException) {
        "{\"code\":-1,\"message\":\"response was not valid UTF-8\"}"
      }
}
