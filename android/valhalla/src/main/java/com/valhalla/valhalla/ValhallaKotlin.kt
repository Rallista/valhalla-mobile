package com.valhalla.valhalla

import com.valhalla.valhalla.http.ValhallaHttpClient

/**
 * Thin JNI surface to the native `libvalhalla-wrapper.so`.
 *
 * Each method maps 1:1 to a `Java_..._native...` entry in `src/wrapper/main.cpp`. Callers must own
 * the actor handle lifecycle — see [ValhallaActor].
 */
internal class ValhallaKotlin {
  companion object {
    init {
      System.loadLibrary("valhalla-wrapper")
    }
  }

  /**
   * Create a native ValhallaActor.
   *
   * Returns a non-zero handle on success, or `0L` if construction fails (invalid config, missing
   * tile extract, etc.). Callers must pass the returned handle to [nativeDestroyActor] exactly
   * once.
   *
   * When [httpClient] is non-null the native actor will fetch missing tiles over HTTP using the URL
   * template in `mjolnir.tile_url`. The bridge keeps a JNI global reference to the client for the
   * actor's lifetime and releases it on [nativeDestroyActor].
   */
  external fun nativeCreateActor(configPath: String, httpClient: ValhallaHttpClient?): Long

  external fun nativeDestroyActor(actorHandle: Long)

  external fun nativeRoute(actorHandle: Long, request: String): String

  external fun nativeTraceAttributes(actorHandle: Long, request: String): String
}
