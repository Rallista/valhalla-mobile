package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.config.ValhallaConfigBuilder
import java.io.File
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end smoke test for pure `mjolnir.tile_dir` mode (no `tile_url`, no `httpClient`).
 *
 * Mirrors [ValhallaTraceAttributesTest] but instead of pointing Valhalla at the bundled
 * `valhalla_tiles.tar` via `withTileExtract`, it first extracts the tar to a directory tree
 * matching Valhalla's canonical `level/x/y.gph` layout, then configures Valhalla with only
 * `withTileDir(extractedDir)`. The Valhalla constructor is invoked with no HTTP client and no tile
 * URL, so Valhalla must read every tile from disk directly via `GraphTile::Create( tile_dir,
 * graphid)`.
 *
 * This is the exact configuration the Narmin off-route engine ended up using after bundle downloads
 * were switched from "mmap the tar" to "extract the tar then delete it." That scenario was
 * producing `code=171, No suitable edges near location` for every match call even though the tile
 * files were present at the expected paths. This test exists to either reproduce that failure
 * inside the wrapper repo (so the underlying cause can be debugged with full native logging) or to
 * confirm the wrapper handles pure tile_dir mode correctly (which would localize the bug to the
 * consumer).
 */
@RunWith(AndroidJUnit4::class)
class ValhallaTileDirOnlyTest {

  private lateinit var appContext: Context
  private lateinit var tileDir: File
  private var valhalla: Valhalla? = null

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext
    tileDir =
        File(appContext.cacheDir, "valhalla_tile_dir_only_test").apply {
          deleteRecursively()
          mkdirs()
        }
    extractBundledTarTo(tileDir)
  }

  @After
  fun tearDown() {
    valhalla?.close()
    valhalla = null
    tileDir.deleteRecursively()
  }

  @Test
  fun traceAttributes_readsTilesFromLocalTileDirOnly() {
    val config = ValhallaConfigBuilder().withTileDir(tileDir.absolutePath).build()
    valhalla = Valhalla(appContext, config)

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
        "tile_dir-only mode should produce matched_points, got: ${rawResponse.take(400)}",
        matchedPoints,
    )
    assertTrue(
        "should have matched both shape points, got ${matchedPoints!!.length()}",
        matchedPoints.length() >= 1,
    )
  }

  /**
   * Extracts the bundled `valhalla_tiles.tar` asset using the same `TarArchiveInputStream` +
   * `copyTo` pattern the Narmin consumer uses, so any extraction-side issue (Commons Compress
   * quirks, padding bytes, atomic-rename timing) reproduces here too.
   */
  private fun extractBundledTarTo(destDir: File) {
    appContext.assets.open(TAR_ASSET).use { input ->
      TarArchiveInputStream(input).use { tar ->
        var entry = tar.nextEntry
        while (entry != null) {
          if (!entry.isDirectory && entry.name.endsWith(".gph")) {
            val outFile = File(destDir, entry.name)
            outFile.parentFile?.mkdirs()
            outFile.outputStream().use { tar.copyTo(it) }
          }
          entry = tar.nextEntry
        }
      }
    }
  }

  private companion object {
    private const val TAR_ASSET = "valhalla_tiles.tar"
  }
}
