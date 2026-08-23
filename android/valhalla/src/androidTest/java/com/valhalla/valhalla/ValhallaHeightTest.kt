package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.api.models.Coordinate
import com.valhalla.api.models.HeightRequest
import com.valhalla.config.ValhallaConfigBuilder
import com.valhalla.config.models.AdditionalData
import com.valhalla.config.models.ValhallaConfig
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import java.io.File
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The Apple tests' elevation tile, a synthetic SRTM tile whose height is
 * `10800 * (lat - 42) + 3600 * (lon - 1)` metres, so heights can be asserted exactly.
 */
@RunWith(AndroidJUnit4::class)
class ValhallaHeightTest {

  private lateinit var appContext: Context
  private lateinit var valhalla: Valhalla
  private lateinit var valhallaWithElevation: Valhalla
  private val instances = mutableListOf<Valhalla>()

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext

    val tarFile = ValhallaFile.usingAsset(appContext, "valhalla_tiles.tar")
    val elevationDir = copyElevationAsset()
    val config = ValhallaConfigBuilder().withTileExtract(tarFile.absolutePath()).build()

    valhalla = open(config, "valhalla-no-height.json")
    valhallaWithElevation =
        open(
            config.copy(additionalData = AdditionalData(elevation = elevationDir.absolutePath)),
            "valhalla-height.json")
  }

  /** Each instance gets its own config file, and is held so teardown can close it. */
  private fun open(config: ValhallaConfig, configName: String): Valhalla {
    val manager = ValhallaConfigManager(appContext, ValhallaFile(appContext, configName))
    return Valhalla(appContext, config, manager).also { instances += it }
  }

  @After
  fun tearDown() {
    instances.forEach { it.close() }
    instances.clear()
  }

  private fun copyElevationAsset(): File {
    val elevationDir = File(appContext.filesDir, "elevation")
    val tile = File(elevationDir, "N42/N42E001.hgt.gz")

    tile.parentFile!!.mkdirs()
    // A resource, not an asset: AGP unzips .gz assets and drops the suffix.
    javaClass.classLoader!!.getResourceAsStream("N42/N42E001.hgt.gz")!!.use { input ->
      tile.outputStream().use { output -> input.copyTo(output) }
    }

    return elevationDir
  }

  @Test
  fun testHeight() {
    val oneRow = 1.0 / 3600.0
    val request =
        HeightRequest(
            shape =
                listOf(
                    Coordinate(lat = 42.5, lon = 1.5),
                    Coordinate(lat = 42.5 + oneRow, lon = 1.5),
                    Coordinate(lat = 42.5, lon = 1.2),
                    Coordinate(lat = 42.5063, lon = 1.5218)))

    val response = valhallaWithElevation.height(request)

    assertEquals(listOf(7200.0, 7203.0, 6120.0, 7347.0), response.height)
  }

  @Test
  fun testHeightWithNoShapeThrows() {
    assertThrows(ValhallaException.Internal::class.java) {
      valhallaWithElevation.height(HeightRequest())
    }
  }

  @Test
  fun testHeightWithoutElevationDataIsNull() {
    val response = valhalla.height(HeightRequest(shape = listOf(Coordinate(lat = 42.5, lon = 1.5))))

    assertEquals(listOf(null), response.height)
  }
}
