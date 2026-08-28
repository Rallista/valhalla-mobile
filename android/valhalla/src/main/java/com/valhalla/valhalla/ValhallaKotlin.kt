package com.valhalla.valhalla

import com.valhalla.valhalla.http.ValhallaHttpClient

internal class ValhallaKotlin {
  companion object {
    init {
      System.loadLibrary("valhalla-wrapper")
    }
  }

  /**
   * Allocate a native actor and build it from [configPath], so the config is read before anything
   * can overwrite it. A config that cannot be read still yields a handle and is reported when the
   * first action retries. Returns 0 only if the handle could not be allocated; the caller owns the
   * result and must pass it to [deleteActor].
   *
   * [httpClient] fetches tiles when the config sets `mjolnir.tile_url`, filling the role
   * `ValhallaMobileHttpClientImpl` fills on iOS. Null turns tile fetching off, so a `tile_url`
   * config then reports every fetch as a failure. The native side holds a global reference to it
   * until [deleteActor].
   */
  external fun createActor(configPath: String, httpClient: ValhallaHttpClient?): Long

  /** Free a handle from [createActor]. Passing 0 is a no-op. */
  external fun deleteActor(handle: Long)

  // UTF-8 bytes rather than strings, which JNI reads as Modified UTF-8. See main.cpp.
  external fun route(handle: Long, request: ByteArray): ByteArray

  external fun traceRoute(handle: Long, request: ByteArray): ByteArray

  external fun traceAttributes(handle: Long, request: ByteArray): ByteArray

  external fun height(handle: Long, request: ByteArray): ByteArray

  external fun matrix(handle: Long, request: ByteArray): ByteArray
}
