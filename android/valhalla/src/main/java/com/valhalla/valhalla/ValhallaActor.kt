package com.valhalla.valhalla

import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import com.valhalla.valhalla.http.ValhallaHttpClient
import java.io.Closeable
import java.util.concurrent.atomic.AtomicLong

/** Internal contract over the native Valhalla actor. */
internal interface ValhallaActorProviding : Closeable {
  fun route(request: String): String

  fun traceAttributes(request: String): String
}

/**
 * Access to the Valhalla routing engine with raw, unchecked JSON strings.
 *
 * Holds a single native ValhallaActor for the lifetime of this Kotlin instance. Construction parses
 * the config and opens the tile extract (mmap), which is expensive — reuse the same instance across
 * many `route` / `traceAttributes` calls.
 *
 * Always call [close] (or use within `use { }`) to release the native actor.
 *
 * @property configPath Filesystem path to a `valhalla.json` config file.
 * @property httpClient Optional HTTP client used by Valhalla to fetch missing tiles over HTTP via
 *   `mjolnir.tile_url`. When `null`, only locally-resident tiles are available.
 */
internal class ValhallaActor(
    configPath: String,
    httpClient: ValhallaHttpClient? = null,
) : ValhallaActorProviding {
  private val valhallaKotlin = ValhallaKotlin()
  private val lock = Any()
  private val handleRef: AtomicLong = AtomicLong(0L)

  init {
    val handle =
        try {
          valhallaKotlin.nativeCreateActor(configPath, httpClient)
        } catch (e: RuntimeException) {
          // The JNI layer surfaces failures by throwing RuntimeException whose
          // message is the canonical `{"code": N, "message": "..."}` payload.
          throw decodeRuntimeException(e)
        }
    require(handle != 0L) { "nativeCreateActor returned a null handle without throwing" }
    handleRef.set(handle)
  }

  /**
   * Run a routing request. Returns the raw JSON response produced by Valhalla.
   *
   * @throws IllegalStateException if [close] has already been called.
   */
  override fun route(request: String): String =
      synchronized(lock) {
        val handle = handleRef.get()
        check(handle != 0L) { "ValhallaActor is closed" }
        valhallaKotlin.nativeRoute(handle, request)
      }

  /**
   * Map-match a GPS trace and return Valhalla's `trace_attributes` JSON response.
   *
   * The request and response shapes follow the Valhalla map-matching API:
   * https://valhalla.github.io/valhalla/api/map-matching/api-reference/
   *
   * Errors during matching are returned as `{"code": N, "message": "..."}`, matching the route()
   * behaviour, not thrown.
   *
   * @throws IllegalStateException if [close] has already been called.
   */
  override fun traceAttributes(request: String): String =
      synchronized(lock) {
        val handle = handleRef.get()
        check(handle != 0L) { "ValhallaActor is closed" }
        valhallaKotlin.nativeTraceAttributes(handle, request)
      }

  /**
   * Release the underlying native actor. Safe to call multiple times; the first call frees the
   * actor, subsequent calls are no-ops. Calling any other method after close throws
   * IllegalStateException.
   */
  override fun close() {
    synchronized(lock) {
      val handle = handleRef.getAndSet(0L)
      if (handle != 0L) {
        valhallaKotlin.nativeDestroyActor(handle)
      }
    }
  }

  private fun decodeRuntimeException(e: RuntimeException): ValhallaException {
    val message = e.message
    if (message != null) {
      val parsed = runCatching { errorAdapter.fromJson(message) }.getOrNull()
      if (parsed != null) {
        return ValhallaException.Internal(parsed)
      }
    }
    return ValhallaException.Internal(
        ErrorResponse(-1, message ?: "Failed to create Valhalla actor"))
  }

  private companion object {
    private val errorAdapter =
        Moshi.Builder().add(KotlinJsonAdapterFactory()).build().adapter(ErrorResponse::class.java)
  }
}
