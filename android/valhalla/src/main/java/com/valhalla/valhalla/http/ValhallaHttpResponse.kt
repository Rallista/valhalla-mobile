package com.valhalla.valhalla.http

/**
 * One tile-server answer, on its way back to the C++ tile getter.
 *
 * The fields are read from JNI by name, so they are `@JvmField` — a Kotlin property would be
 * reached through a getter method instead, and the names here have to stay in step with the field
 * lookups in `src/wrapper/main.cpp`.
 *
 * @property success whether the request produced a usable answer. A transport failure and an HTTP
 *   error are both `false`; [httpCode] tells them apart.
 * @property httpCode the HTTP status, or `0` when the request never got that far.
 * @property lastModified the `Last-Modified` header as seconds since the epoch, or `0` when it was
 *   absent, unparseable, or not asked for.
 * @property body the response body, or `null` for a `HEAD` or a failure.
 */
internal class ValhallaHttpResponse(
    @JvmField val success: Boolean,
    @JvmField val httpCode: Int,
    @JvmField val lastModified: Long,
    @JvmField val body: ByteArray?,
) {
  companion object {
    /** A request that never reached a server. */
    fun failure(httpCode: Int = 0): ValhallaHttpResponse =
        ValhallaHttpResponse(success = false, httpCode = httpCode, lastModified = 0, body = null)
  }
}
