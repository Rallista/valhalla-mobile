package com.valhalla.valhalla

import android.content.Context
import android.content.res.AssetManager
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.valhalla.config.ValhallaConfigFactory
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import com.valhalla.valhalla.http.ValhallaHttpClient
import com.valhalla.valhalla.http.ValhallaHttpResponse
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import java.util.zip.GZIPInputStream
import java.util.zip.GZIPOutputStream
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

private fun gzip(bytes: ByteArray): ByteArray {
  val out = ByteArrayOutputStream()
  GZIPOutputStream(out).use { it.write(bytes) }
  return out.toByteArray()
}

private fun gunzip(bytes: ByteArray): ByteArray =
    GZIPInputStream(bytes.inputStream()).use { it.readBytes() }

/** Serves tiles from the test assets without a network, as whatever body a test asks for. */
private class FakeTileClient(private val assets: AssetManager) : ValhallaHttpClient() {

  data class Request(val path: String, val acceptGzip: Boolean)

  /** Turns a stored tile into the body sent for it. */
  @Volatile var body: (ByteArray) -> ByteArray = { it }

  val requests = CopyOnWriteArrayList<Request>()

  fun tile(path: String) = assets.open("valhalla_tiles/$path").use { it.readBytes() }

  override fun get(
      url: String,
      rangeOffset: Long,
      rangeSize: Long,
      acceptGzip: Boolean
  ): ValhallaHttpResponse {
    val path = url.substringAfter(BASE_URL)
    requests += Request(path, acceptGzip)
    val bytes =
        try {
          tile(path)
        } catch (e: IOException) {
          return ValhallaHttpResponse.failure(404)
        }
    return ValhallaHttpResponse(
        success = true, httpCode = 200, lastModified = 0, body = body(bytes))
  }

  companion object {
    const val BASE_URL = "http://tiles.invalid/"
  }
}

/** How the shared C++ tile getter stores what a client hands it. */
@RunWith(AndroidJUnit4::class)
class ValhallaTileUrlTest {

  private lateinit var context: Context
  private lateinit var tilesDir: File
  private lateinit var client: FakeTileClient

  @Before
  fun setUp() {
    context = InstrumentationRegistry.getInstrumentation().targetContext
    tilesDir = File(context.cacheDir, "tile-url-${UUID.randomUUID()}").apply { mkdirs() }
    client = FakeTileClient(context.assets)
  }

  @After
  fun tearDown() {
    if (::tilesDir.isInitialized) tilesDir.deleteRecursively()
  }

  /** Routes with a new actor, as a fresh app launch does, and returns the trip status. */
  private fun route(gzipped: Boolean): String? {
    val config =
        ValhallaConfigFactory.usingTileUrl(
            "${FakeTileClient.BASE_URL}{tilePath}", tilesDir.absolutePath, gzipped)
    val file = ValhallaFile(context, "tile-url.json")
    ValhallaConfigManager(context, file).writeConfig(config)
    val actor = ValhallaActor(file.absolutePath(), client)
    try {
      return JSONObject(actor.route(ANDORRA_ROUTE))
          .optJSONObject("trip")
          ?.getString("status_message")
    } finally {
      actor.close()
    }
  }

  private fun storedTiles(): Map<String, ByteArray> =
      tilesDir
          .walkTopDown()
          .filter { it.isFile && (it.name.endsWith(".gph") || it.name.endsWith(".gph.gz")) }
          .associate { it.relativeTo(tilesDir).path to it.readBytes() }

  private fun assertStoredGzipped() {
    val tiles = storedTiles()
    assertFalse("nothing was stored", tiles.isEmpty())
    for ((path, stored) in tiles) {
      assertTrue(path, path.endsWith(".gph.gz"))
      assertArrayEquals(path, client.tile(path.removeSuffix(".gz")), gunzip(stored))
    }
  }

  @Test
  fun testKeepsGzipBodiesWithTheFlagOn() {
    client.body = ::gzip

    assertEquals(FOUND, route(gzipped = true))

    assertTrue(client.requests.all { it.acceptGzip })
    assertStoredGzipped()
  }

  @Test
  fun testCompressesPlainBodiesWithTheFlagOn() {
    assertEquals(FOUND, route(gzipped = true))

    assertStoredGzipped()
  }

  @Test
  fun testInflatesGzipBodiesWithTheFlagOff() {
    client.body = ::gzip

    assertEquals(FOUND, route(gzipped = false))

    assertTrue(client.requests.none { it.acceptGzip })
    val tiles = storedTiles()
    assertFalse("nothing was stored", tiles.isEmpty())
    for ((path, stored) in tiles) {
      assertTrue(path, path.endsWith(".gph"))
      assertArrayEquals(path, client.tile(path), stored)
    }
  }

  @Test
  fun testRejectsBodiesThatAreNotOneWholeTile() {
    val page = "<html>${"Sign in. ".repeat(100)}</html>".toByteArray()
    val bodies =
        mapOf<String, (ByteArray) -> ByteArray>(
            "empty" to { ByteArray(0) },
            "an html page" to { page },
            "a truncated tile" to { it.copyOf(it.size / 2) },
            "gzip with a corrupt tail" to
                {
                  gzip(it).also { gz ->
                    gz[gz.size - 20] = (gz[gz.size - 20].toInt() xor 0xff).toByte()
                  }
                },
            "gzip with bytes after it" to { gzip(it) + byteArrayOf(0) },
            "gzip bigger than its header says" to { gzip(it + ByteArray(1 shl 20)) },
            // Read as a header, the text claims a tile of over 500 MB.
            "a gzipped html page" to { gzip(page) },
        )
    for ((name, body) in bodies) {
      for (gzipped in listOf(true, false)) {
        client.body = body
        client.requests.clear()
        assertNull("$name, gzip $gzipped", route(gzipped))
        assertTrue("$name was not fetched, gzip $gzipped", client.requests.isNotEmpty())
        assertTrue("$name was stored, gzip $gzipped", storedTiles().isEmpty())
      }
    }
  }

  private companion object {
    const val FOUND = "Found route between points"
    const val ANDORRA_ROUTE =
        "{\"locations\":[{\"lat\":42.5063,\"lon\":1.5218},{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\",\"units\":\"miles\"}"
  }
}
