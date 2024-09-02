package com.valhalla.valhalla

import ValhallaConfigBuilder
import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.api.models.CostingModel
import com.valhalla.api.models.DirectionsOptions
import com.valhalla.api.models.RouteRequest
import com.valhalla.api.models.RoutingWaypoint
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ValhallaJsonFormatTileTarTest {

  private lateinit var appContext: Context
  private lateinit var configManager: ValhallaConfigManager
  private lateinit var valhalla: Valhalla

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext
    configManager = ValhallaConfigManager(appContext)

    val tarFile = ValhallaFile.usingAsset(appContext, "valhalla_tiles.tar")
    val config = ValhallaConfigBuilder().withTileExtract(tarFile.absolutePath()).build()

    valhalla = Valhalla(appContext, config, configManager)
  }

  @Test
  fun test_noSuitableEdges() {
    val request =
        RouteRequest(
            locations =
                listOf(
                    RoutingWaypoint(lat = 45.843812, lon = -123.768205),
                    RoutingWaypoint(lat = 45.869701, lon = -123.766121)),
            costing = CostingModel.auto,
            directionsOptions = DirectionsOptions(format = DirectionsOptions.Format.json))

    // Expect an exception w/ 171: No suitable edges near location
    val exception = assertThrows(ValhallaException::class.java) { valhalla.route(request) }

    assert(exception is ValhallaException.Internal)
    assertEquals("ValhallaError(code=171, No suitable edges near location)", exception.message)
  }

  @Test
  fun test_success() {
    val request =
        RouteRequest(
            locations =
                listOf(
                    RoutingWaypoint(lat = 38.429719, lon = -108.827425),
                    RoutingWaypoint(lat = 38.4604331, lon = -108.8817009)),
            costing = CostingModel.auto)

    when (val response = valhalla.route(request)) {
      is ValhallaResponse.Json -> {
        val it = response.jsonResponse
        assertEquals(it.trip.status, 0)
      }
      is ValhallaResponse.Osrm -> fail("format should not be osrm")
    }
  }
}
