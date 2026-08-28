package com.valhalla.valhalla.http

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

/**
 * Fetches tiles over HTTP for the C++ tile getter, when the config sets `mjolnir.tile_url`.
 *
 * This is the Android half of `ValhallaMobileHttpClient`, the interface `src/wrapper` declares for
 * both platforms. iOS implements it directly in Obj-C++ with `NSURLConnection`; here C++ calls back
 * into [get] and [head] through JNI.
 *
 * [java.net.HttpURLConnection] rather than a third-party client, so that consumers of the published
 * library inherit no HTTP dependency of ours — the same reason iOS uses the platform's own stack.
 *
 * Neither method throws. The tile getter has no way to receive an exception, and a failed fetch is
 * an ordinary event — a tile that is simply not on the server — so every failure comes back as an
 * unsuccessful [ValhallaHttpResponse] instead.
 *
 * Two things a caller has to know:
 * * The consuming app needs `<uses-permission android:name="android.permission.INTERNET" />`. This
 *   library does not declare it, because that would force the permission on every consumer,
 *   including the offline-only ones. Without it every fetch fails.
 * * Requests are synchronous, on whichever thread ran the routing action. Routing on the main
 *   thread with a `tile_url` config therefore trips `NetworkOnMainThreadException`, which is
 *   reported here as a failed fetch.
 */
internal class ValhallaHttpClient(
    private val connectTimeoutMillis: Int = DEFAULT_TIMEOUT_MILLIS,
    private val readTimeoutMillis: Int = DEFAULT_TIMEOUT_MILLIS,
) {

  /**
   * Fetches a tile, or a byte range of one.
   *
   * @param url the tile URL, already filled in by valhalla.
   * @param rangeOffset first byte to request. Only used when [rangeSize] is positive.
   * @param rangeSize how many bytes to request; `0` asks for the whole resource.
   */
  fun get(url: String, rangeOffset: Long, rangeSize: Long): ValhallaHttpResponse =
      perform(url, method = "GET", headerMask = 0) { connection ->
        if (rangeSize > 0) {
          // Inclusive on both ends, so the last byte is offset + size - 1.
          connection.setRequestProperty(
              "Range", "bytes=$rangeOffset-${rangeOffset + rangeSize - 1}")
        }
      }

  /**
   * Asks for a tile's headers without its body, to find out whether a cached copy is stale.
   *
   * @param url the tile URL.
   * @param headerMask which headers the caller wants. Only [HEADER_LAST_MODIFIED] is understood;
   *   anything else is ignored, and the corresponding field is left at zero.
   */
  fun head(url: String, headerMask: Int): ValhallaHttpResponse =
      perform(url, method = "HEAD", headerMask = headerMask) {}

  private fun perform(
      url: String,
      method: String,
      headerMask: Int,
      configure: (HttpURLConnection) -> Unit,
  ): ValhallaHttpResponse {
    var connection: HttpURLConnection? = null
    return try {
      connection =
          (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = connectTimeoutMillis
            readTimeout = readTimeoutMillis
            // HttpURLConnection otherwise offers gzip on its own and silently inflates what comes
            // back. Valhalla decides for itself whether tiles are gzipped, from `tile_url_gz`, and
            // inflates them itself — so it has to receive exactly the bytes on the wire.
            setRequestProperty("Accept-Encoding", "identity")
            configure(this)
          }

      val httpCode = connection.responseCode
      if (httpCode !in HTTP_OK_RANGE) {
        return ValhallaHttpResponse.failure(httpCode)
      }

      val lastModified =
          if (headerMask and HEADER_LAST_MODIFIED != 0) {
            // getHeaderFieldDate reads all three date formats HTTP allows, and answers in
            // milliseconds. The tile getter counts in seconds.
            TimeUnit.MILLISECONDS.toSeconds(connection.getHeaderFieldDate("Last-Modified", 0L))
          } else {
            0L
          }

      val body = if (method == "GET") connection.inputStream.use { it.readBytes() } else null

      ValhallaHttpResponse(
          success = true, httpCode = httpCode, lastModified = lastModified, body = body)
    } catch (e: IOException) {
      // A refused connection, a timeout, a DNS failure, or a body that ended early.
      ValhallaHttpResponse.failure()
    } catch (e: SecurityException) {
      // The consuming app is missing the INTERNET permission.
      ValhallaHttpResponse.failure()
    } catch (e: RuntimeException) {
      // A malformed URL from the config, or NetworkOnMainThreadException. Neither may reach the
      // C++ caller, which has no way to handle a Java exception.
      ValhallaHttpResponse.failure()
    } finally {
      connection?.disconnect()
    }
  }

  companion object {
    /** Matches `tile_getter_t::kHeaderLastModified` in valhalla's `baldr/tilegetter.h`. */
    const val HEADER_LAST_MODIFIED: Int = 1

    private const val DEFAULT_TIMEOUT_MILLIS = 10_000

    private val HTTP_OK_RANGE = 200..299
  }
}
