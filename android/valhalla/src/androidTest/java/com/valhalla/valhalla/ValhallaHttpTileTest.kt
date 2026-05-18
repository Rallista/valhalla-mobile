package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.config.ValhallaConfigBuilder
import com.valhalla.valhalla.http.ValhallaHttpClient
import java.io.File
import java.util.concurrent.atomic.AtomicInteger
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end smoke test for the JNI HTTP tile bridge (Option D).
 *
 * Forces Valhalla to fetch every tile through a Kotlin [ValhallaHttpClient] by:
 * 1. Configuring an empty local `mjolnir.tile_dir` (no preloaded tiles).
 * 2. Setting `mjolnir.tile_url` to a stub URL template via the new
 *    [Valhalla] constructor parameter.
 * 3. Pre-extracting the bundled `valhalla_tiles.tar` to a "ground truth"
 *    directory that the stub serves bytes from.
 *
 * If the JNI bridge is broken or the Valhalla constructor fails to inject
 * `mjolnir.tile_url`, the matcher cannot load any tile and Valhalla returns an
 * error response. A successful `trace_attributes` call across the same Andorra
 * coordinates the other smoke tests use is therefore a strong end-to-end signal.
 */
@RunWith(AndroidJUnit4::class)
class ValhallaHttpTileTest {

  private lateinit var appContext: Context
  private lateinit var groundTruthDir: File
  private lateinit var tileDir: File
  private var valhalla: Valhalla? = null

  private val getCallCount = AtomicInteger(0)
  private val headCallCount = AtomicInteger(0)

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext

    groundTruthDir =
        File(appContext.cacheDir, "valhalla_http_test_ground_truth").apply {
          deleteRecursively()
          mkdirs()
        }
    extractTar(groundTruthDir)

    tileDir =
        File(appContext.cacheDir, "valhalla_http_test_tile_dir").apply {
          deleteRecursively()
          mkdirs()
        }
  }

  @After
  fun tearDown() {
    valhalla?.close()
    valhalla = null
    groundTruthDir.deleteRecursively()
    tileDir.deleteRecursively()
  }

  @Test
  fun traceAttributes_fetchesTilesViaHttpClient() {
    val stub =
        object : ValhallaHttpClient {
          override fun get(
              url: String,
              rangeOffset: Long,
              rangeSize: Long,
          ): ValhallaHttpClient.GetResponse {
            getCallCount.incrementAndGet()
            val file = resolveStubFile(url) ?: return notFoundGet()
            val bytes =
                if (rangeSize > 0) {
                  file.inputStream().use { stream ->
                    stream.skip(rangeOffset)
                    val buf = ByteArray(rangeSize.toInt())
                    val read = stream.read(buf)
                    if (read < 0) ByteArray(0) else buf.copyOf(read)
                  }
                } else {
                  file.readBytes()
                }
            return ValhallaHttpClient.GetResponse(
                success = true, httpCode = 200, body = bytes)
          }

          override fun head(url: String, headerMask: Int): ValhallaHttpClient.HeadResponse {
            headCallCount.incrementAndGet()
            val file = resolveStubFile(url) ?: return notFoundHead()
            return ValhallaHttpClient.HeadResponse(
                success = true,
                httpCode = 200,
                lastModifiedTime = file.lastModified() / 1000,
            )
          }
        }

    val config = ValhallaConfigBuilder().withTileDir(tileDir.absolutePath).build()
    valhalla =
        Valhalla(
            appContext,
            config,
            httpClient = stub,
            tileUrl = TILE_URL_TEMPLATE,
            tileUrlGz = false,
        )

    val rawRequest =
        """
        {
          "shape": [
            {"lat": 42.5063, "lon": 1.5218, "time": 0, "accuracy": 10},
            {"lat": 42.5086, "lon": 1.5394, "time": 120, "accuracy": 10}
          ],
          "costing": "auto",
          "shape_match": "map_snap",
          "trace_options": {
            "search_radius": 100,
            "gps_accuracy": 15,
            "max_route_distance_factor": 10,
            "max_route_time_factor": 10
          }
        }
        """
            .trimIndent()

    val rawResponse = valhalla!!.traceAttributesRaw(rawRequest)
    val json = JSONObject(rawResponse)

    val matchedPoints = json.optJSONArray("matched_points")
    assertNotNull(
        "response should include matched_points; got ${rawResponse.take(200)}", matchedPoints)
    assertTrue(
        "JNI bridge should have invoked the stub at least once (get=${getCallCount.get()}," +
            " head=${headCallCount.get()})",
        getCallCount.get() > 0 || headCallCount.get() > 0,
    )
  }

  private fun resolveStubFile(url: String): File? {
    val relativePath = url.substringAfter(TILE_URL_PREFIX, missingDelimiterValue = "")
    if (relativePath.isEmpty() || relativePath == url) return null
    val file = File(groundTruthDir, relativePath)
    return if (file.exists() && file.isFile) file else null
  }

  private fun notFoundGet() = ValhallaHttpClient.GetResponse(success = false, httpCode = 404)

  private fun notFoundHead() = ValhallaHttpClient.HeadResponse(success = false, httpCode = 404)

  private fun extractTar(dest: File) {
    appContext.assets.open(TILE_TAR_ASSET).use { stream ->
      TarArchiveInputStream(stream).use { tar ->
        var entry = tar.nextEntry
        while (entry != null) {
          if (!entry.isDirectory) {
            val out = File(dest, entry.name)
            out.parentFile?.mkdirs()
            out.outputStream().use { tar.copyTo(it) }
          }
          entry = tar.nextEntry
        }
      }
    }
  }

  private companion object {
    private const val TILE_TAR_ASSET = "valhalla_tiles.tar"
    private const val TILE_URL_PREFIX = "http://stub.invalid/"
    private const val TILE_URL_TEMPLATE = "${TILE_URL_PREFIX}{tilePath}"
  }
}
