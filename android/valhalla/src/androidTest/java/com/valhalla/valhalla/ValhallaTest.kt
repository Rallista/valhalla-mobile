package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.api.models.CostingModel
import com.valhalla.api.models.DirectionsOptions
import com.valhalla.api.models.RouteRequest
import com.valhalla.api.models.RoutingWaypoint
import com.valhalla.valhalla.config.ValhallaConfig
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ValhallaInstrumentedTest {

  private lateinit var appContext: Context
  private lateinit var configManager: ValhallaConfigManager

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext
    configManager = ValhallaConfigManager(appContext)
  }

  @Test
  fun test_valhallaFormattedRequest_usingTar() {
    val tarFile = ValhallaFile.UsingAsset(appContext, "valhalla_tiles.tar")
    val config = ValhallaConfig.usingTileTar(tarFile)

    val valhalla = Valhalla(appContext, config, configManager)

    val request =
        RouteRequest(
            locations =
                listOf(
                    RoutingWaypoint(lat = 45.843812, lon = -123.768205),
                    RoutingWaypoint(lat = 45.869701, lon = -123.766121)),
            costing = CostingModel.auto,
            directionsOptions = DirectionsOptions(format = DirectionsOptions.Format.json))

    when (val response = valhalla.route(request)) {
      is ValhallaResponse.Json -> {
        val it = response.jsonResponse
        assertEquals("", it.trip.status)
      }
      is ValhallaResponse.Osrm -> fail("format was not osrm")
    }
  }
}
