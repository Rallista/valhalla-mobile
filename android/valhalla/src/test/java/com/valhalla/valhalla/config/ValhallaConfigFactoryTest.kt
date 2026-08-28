package com.valhalla.valhalla.config

import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import com.valhalla.config.models.ValhallaConfig
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * These run on the JVM rather than on a device: building a config touches no native library and no
 * Android [android.content.Context], which is the point of reading the defaults from a java
 * resource. The instrumented tests cover what happens once a config reaches the engine.
 */
class ValhallaConfigFactoryTest {

  private val moshi: Moshi = Moshi.Builder().add(KotlinJsonAdapterFactory()).build()

  /** The bundled resource is present in the artifact and parses. */
  @Test
  fun defaultIsReadable() {
    val config = ValhallaConfigFactory.default()

    assertNotNull(config.mjolnir)
    assertNotNull(config.loki)
    assertNotNull(config.thor)
    assertNotNull(config.serviceLimits)
  }

  /**
   * The defaults come from valhalla, not from the generated data classes.
   *
   * `Mjolnir.admin` defaults to `/custom_data/admins.sqlite` in the model and
   * `/data/valhalla/admin.sqlite` in valhalla's own config, so this tells the two apart. Reading
   * the model default here would mean the resource had not been parsed at all.
   */
  @Test
  fun defaultComesFromValhallaNotTheModelDefaults() {
    val config = ValhallaConfigFactory.default()

    assertEquals("/data/valhalla/admin.sqlite", config.mjolnir?.admin)
    assertEquals("/data/valhalla/tz_world.sqlite", config.mjolnir?.timezone)
    assertEquals("/data/valhalla/elevation/", config.additionalData?.elevation)
  }

  /**
   * Every key in the bundled config is one the models know.
   *
   * Without `failOnUnknown` Moshi skips what it does not recognise, so a key the models have
   * drifted away from would be dropped in silence — which is exactly what three misspelled keys
   * did to all 32 hierarchy-limit settings.
   */
  @Test
  fun defaultResourceIsFullyModelled() {
    val json =
        requireNotNull(
                ValhallaConfigFactory::class
                    .java
                    .getResourceAsStream("/com/valhalla/valhalla/default.json"))
            .use { it.readBytes().decodeToString() }

    val config = moshi.adapter(ValhallaConfig::class.java).failOnUnknown().fromJson(json)

    assertNotNull(config)
  }

  /** iOS and Android start from the same bytes, so the hierarchy limits have to be there. */
  @Test
  fun defaultCarriesHierarchyLimits() {
    val config = ValhallaConfigFactory.default()

    assertNotNull(config.thor?.costmatrix?.hierarchyLimits)
    assertNotNull(config.thor?.bidirectionalAstar?.hierarchyLimits)
    assertEquals(2800, config.thor?.costmatrix?.maxIterations)
  }

  @Test
  fun usingTileExtractSetsTheTarAndLeavesElevationAlone() {
    val config = ValhallaConfigFactory.usingTileExtract("/data/app/valhalla_tiles.tar")

    assertEquals("/data/app/valhalla_tiles.tar", config.mjolnir?.tileExtract)
    // Untouched, so it still holds valhalla's own default rather than a path we invented.
    assertEquals("/data/valhalla/elevation/", config.additionalData?.elevation)
  }

  @Test
  fun usingTileExtractSetsElevationWhenGiven() {
    val config =
        ValhallaConfigFactory.usingTileExtract(
            "/data/app/valhalla_tiles.tar", elevationDir = "/data/app/elevation")

    assertEquals("/data/app/valhalla_tiles.tar", config.mjolnir?.tileExtract)
    assertEquals("/data/app/elevation", config.additionalData?.elevation)
  }

  @Test
  fun usingTilesDirSetsTheDirectory() {
    val config = ValhallaConfigFactory.usingTilesDir("/data/app/tiles", elevationDir = "/data/app/dem")

    assertEquals("/data/app/tiles", config.mjolnir?.tileDir)
    assertEquals("/data/app/dem", config.additionalData?.elevation)
  }

  /** Matches Swift's `ValhallaConfig(tilesUrl:tilesDir:tilesAreGzFiles:)`, connectivity flag and all. */
  @Test
  fun usingTileUrlConfiguresFetching() {
    val config =
        ValhallaConfigFactory.usingTileUrl(
            tilesUrl = "https://tiles.example/{tilePath}",
            tilesDir = "/data/app/tiles",
            tilesAreGzFiles = true)

    assertEquals("https://tiles.example/{tilePath}", config.mjolnir?.tileUrl)
    assertEquals(true, config.mjolnir?.tileUrlGz)
    assertEquals("/data/app/tiles", config.mjolnir?.tileDir)
    // The connectivity map is built from the tiles that are present, so it cannot answer for
    // tiles that have not been downloaded yet.
    assertEquals(false, config.loki?.useConnectivity)
  }

  /**
   * The C++ wrapper only attaches a tile getter when `tile_url` is non-empty, so a config built
   * for offline use must not carry one — otherwise a missing loose tile turns into a fetch against
   * an empty URL instead of routing around the gap.
   */
  @Test
  fun offlineConfigsCarryNoTileUrl() {
    assertTrue(ValhallaConfigFactory.usingTileExtract("/tiles.tar").mjolnir?.tileUrl.isNullOrEmpty())
    assertTrue(ValhallaConfigFactory.usingTilesDir("/tiles").mjolnir?.tileUrl.isNullOrEmpty())
  }

  @Test
  fun fromJsonReadsAWholeConfig() {
    val json = moshi.adapter(ValhallaConfig::class.java).toJson(ValhallaConfigFactory.default())

    val config = ValhallaConfigFactory.fromJson(json)

    assertEquals("/data/valhalla/admin.sqlite", config.mjolnir?.admin)
  }

  @Test
  fun fromJsonRejectsMalformedInput() {
    assertThrows(IllegalArgumentException::class.java) {
      ValhallaConfigFactory.fromJson("{\"mjolnir\":")
    }
  }

  @Test
  fun fromJsonRejectsTheLiteralNull() {
    assertThrows(IllegalArgumentException::class.java) { ValhallaConfigFactory.fromJson("null") }
  }

  @Test
  fun fromFileReadsFromDisk() {
    val file = File.createTempFile("valhalla-config", ".json")
    file.deleteOnExit()
    file.writeText(
        moshi
            .adapter(ValhallaConfig::class.java)
            .toJson(ValhallaConfigFactory.usingTileExtract("/data/app/tiles.tar")))

    val config = ValhallaConfigFactory.fromFile(file)

    assertEquals("/data/app/tiles.tar", config.mjolnir?.tileExtract)
  }

  /**
   * The default is parsed once and shared, so building on it must not mutate what the next caller
   * sees. [ValhallaConfig] is a data class and every function here goes through `copy`, which is
   * what makes that safe — this pins it.
   */
  @Test
  fun buildingDoesNotMutateTheSharedDefault() {
    ValhallaConfigFactory.usingTileExtract("/first.tar", elevationDir = "/first/dem")
    ValhallaConfigFactory.usingTileUrl("https://tiles.example/{tilePath}", "/first/tiles")

    val pristine = ValhallaConfigFactory.default()

    assertEquals("/data/valhalla/tiles.tar", pristine.mjolnir?.tileExtract)
    assertEquals("/data/valhalla/elevation/", pristine.additionalData?.elevation)
    assertTrue(pristine.mjolnir?.tileUrl.isNullOrEmpty())
    assertNotEquals(false, pristine.loki?.useConnectivity)
  }
}
