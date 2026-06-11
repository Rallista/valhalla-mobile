package com.valhalla.valhalla.http

import java.io.IOException
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import okhttp3.OkHttpClient
import okhttp3.Request

/**
 * Default OkHttp-backed implementation of [ValhallaHttpClient]. Suitable for production use.
 *
 * Callers can pass a preconfigured [OkHttpClient] (interceptors, auth, custom timeouts). The
 * supplied client must outlive any active [com.valhalla.valhalla.Valhalla] instance that uses this
 * adapter; the adapter does not own the client.
 */
class OkHttpValhallaHttpClient(
    private val client: OkHttpClient = OkHttpClient(),
) : ValhallaHttpClient {

  override fun get(
      url: String,
      rangeOffset: Long,
      rangeSize: Long,
  ): ValhallaHttpClient.GetResponse {
    val builder = Request.Builder().url(url)
    if (rangeSize > 0) {
      val end = rangeOffset + rangeSize - 1
      builder.header("Range", "bytes=$rangeOffset-$end")
    }
    return try {
      client.newCall(builder.build()).execute().use { resp ->
        if (!resp.isSuccessful) {
          return ValhallaHttpClient.GetResponse(success = false, httpCode = resp.code)
        }
        val bytes = resp.body?.bytes()
        ValhallaHttpClient.GetResponse(
            success = bytes != null,
            httpCode = resp.code,
            body = bytes,
        )
      }
    } catch (_: IOException) {
      ValhallaHttpClient.GetResponse(success = false)
    }
  }

  override fun head(url: String, headerMask: Int): ValhallaHttpClient.HeadResponse {
    val request = Request.Builder().url(url).head().build()
    return try {
      client.newCall(request).execute().use { resp ->
        if (!resp.isSuccessful) {
          return ValhallaHttpClient.HeadResponse(success = false, httpCode = resp.code)
        }
        val wantsLastModified = headerMask and ValhallaHttpClient.HEADER_MASK_LAST_MODIFIED != 0
        val lastModified =
            if (wantsLastModified) parseHttpDate(resp.header("Last-Modified")) else 0L
        ValhallaHttpClient.HeadResponse(
            success = true,
            httpCode = resp.code,
            lastModifiedTime = lastModified,
        )
      }
    } catch (_: IOException) {
      ValhallaHttpClient.HeadResponse(success = false)
    }
  }

  private fun parseHttpDate(value: String?): Long {
    if (value.isNullOrBlank()) return 0L
    return try {
      OffsetDateTime.parse(value, DateTimeFormatter.RFC_1123_DATE_TIME).toEpochSecond()
    } catch (_: Exception) {
      0L
    }
  }
}
