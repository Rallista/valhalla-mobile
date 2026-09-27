package com.valhalla.valhalla.http

import com.sun.net.httpserver.HttpServer
import java.io.ByteArrayOutputStream
import java.net.InetSocketAddress
import java.util.zip.GZIPOutputStream
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** Against the JDK's HttpURLConnection, which never negotiates gzip on its own. */
class ValhallaHttpClientTest {

  private lateinit var server: HttpServer
  private lateinit var baseUrl: String

  // Shared between the test thread and the server's handler thread.
  /** `Accept-Encoding` from the most recent request. */
  @Volatile private var sentAcceptEncoding: String? = null

  /** The stored tile, uncompressed. The server gzips it when asked. */
  @Volatile
  private var payload: ByteArray = "a tile, long enough that gzip changes it".toByteArray()

  @Before
  fun startServer() {
    server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
    server.createContext("/tile") { exchange ->
      val accept = exchange.requestHeaders.getFirst("Accept-Encoding")
      sentAcceptEncoding = accept

      val encoding = if (accept?.contains("gzip") == true) "gzip" else "identity"
      val body = if (encoding == "gzip") gzip(payload) else payload

      if (encoding != "identity") exchange.responseHeaders.add("Content-Encoding", encoding)
      exchange.sendResponseHeaders(200, body.size.toLong())
      exchange.responseBody.use { it.write(body) }
    }
    server.start()
    baseUrl = "http://127.0.0.1:${server.address.port}/tile"
  }

  @After
  fun stopServer() {
    server.stop(0)
  }

  private fun gzip(bytes: ByteArray): ByteArray {
    val out = ByteArrayOutputStream()
    GZIPOutputStream(out).use { it.write(bytes) }
    return out.toByteArray()
  }

  @Test
  fun leavesEncodingToPlatformForWholeTile() {
    val response = ValhallaHttpClient().get(baseUrl, 0, 0)

    assertNull(sentAcceptEncoding)
    assertTrue(response.success)
    assertArrayEquals(payload, response.body)
  }

  @Test
  fun asksForIdentityOnRangeRequest() {
    ValhallaHttpClient().get(baseUrl, 0, 4)

    assertEquals("identity", sentAcceptEncoding)
  }
}
