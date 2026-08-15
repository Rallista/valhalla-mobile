package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.api.models.CostingModel
import com.valhalla.api.models.DirectionsOptions
import com.valhalla.api.models.MapMatchCostingModel
import com.valhalla.api.models.MapMatchRequest
import com.valhalla.api.models.MapMatchWaypoint
import com.valhalla.api.models.RouteRequest
import com.valhalla.api.models.RoutingWaypoint
import com.valhalla.api.models.TraceAttributeFilterOptions
import com.valhalla.api.models.TraceAttributeKey
import com.valhalla.api.models.TraceAttributesRequest
import com.valhalla.config.ValhallaConfigBuilder
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Exercises the map-matching actions against the bundled Andorra tile extract.
 *
 * The traces here are not hand-written coordinates: each test first asks Valhalla for a route
 * between two points known to be covered by the fixture, then feeds that route's shape back in as
 * the trace. The shape comes off the graph itself, so it matches the road network exactly and the
 * tests assert on matching rather than on how faithfully some invented coordinates happen to sit on
 * an Andorran road.
 */
@RunWith(AndroidJUnit4::class)
class ValhallaTraceTest {

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

  /**
   * The shape of a known-good route through the fixture, as a polyline with six digits of
   * precision — which is what the trace actions expect.
   */
  private fun routeShape(): String {
    val request =
        RouteRequest(
            locations =
                listOf(
                    RoutingWaypoint(lat = 42.5063, lon = 1.5218),
                    RoutingWaypoint(lat = 42.5086, lon = 1.5394)),
            costing = CostingModel.auto,
            format = RouteRequest.Format.json)

    return when (val response = valhalla.route(request)) {
      is ValhallaResponse.Json -> response.jsonResponse.trip.legs.first().shape
      is ValhallaResponse.Osrm -> throw AssertionError("format should not be osrm")
    }
  }

  @Test
  fun test_traceRoute_success() {
    val request =
        MapMatchRequest(encodedPolyline = routeShape(), costing = MapMatchCostingModel.auto)

    val response = valhalla.traceRoute(request)

    assertEquals(0, response.trip.status)
    assertEquals("Found route between points", response.trip.statusMessage)
    assertTrue("expected at least one matched leg", response.trip.legs.isNotEmpty())
  }

  @Test
  fun test_traceRoute_noSuitableEdges() {
    // The same Oregon coordinates the routing tests use to miss the Andorra fixture.
    val request =
        MapMatchRequest(
            shape =
                listOf(
                    MapMatchWaypoint(lat = 45.843812, lon = -123.768205),
                    MapMatchWaypoint(lat = 45.869701, lon = -123.766121)),
            costing = MapMatchCostingModel.auto)

    // Which code comes back depends on how far the matcher gets before giving up — Loki can
    // reject the locations outright, or Meili can fail to find a path — so assert that the
    // engine reported a failure rather than pinning a code that is not ours to guarantee.
    val exception = assertThrows(ValhallaException::class.java) { valhalla.traceRoute(request) }

    assertTrue(
        "expected a Valhalla error, got: ${exception.message}",
        exception is ValhallaException.Internal)
  }

  @Test
  fun test_traceRoute_osrmFormatNotSupported() {
    val request =
        MapMatchRequest(
            encodedPolyline = routeShape(),
            costing = MapMatchCostingModel.auto,
            directionsOptions = DirectionsOptions(format = DirectionsOptions.Format.osrm))

    assertThrows(ValhallaException.NotSupported::class.java) { valhalla.traceRoute(request) }
  }

  /**
   * The OSRM response the typed API refuses is still reachable raw, and — importantly — is not
   * mistaken for an error. A successful OSRM map match carries a top-level `"code": "Ok"` and
   * reports its routes under `matchings`, which is exactly the shape a naive error check trips
   * over.
   */
  @Test
  fun test_traceRouteRaw_osrmFormat() {
    val requestJson =
        """{"encoded_polyline":${quote(routeShape())},"costing":"auto","format":"osrm"}"""

    val rawResponse = valhalla.traceRouteRaw(requestJson)

    assertTrue("expected osrm matchings, got: $rawResponse", rawResponse.contains("\"matchings\""))
    assertTrue(
        "expected osrm tracepoints, got: $rawResponse", rawResponse.contains("\"tracepoints\""))
  }

  @Test
  fun test_traceAttributes_success() {
    val request =
        TraceAttributesRequest(encodedPolyline = routeShape(), costing = MapMatchCostingModel.auto)

    val response = valhalla.traceAttributes(request)

    val edges = response.edges
    assertNotNull("expected matched edges", edges)
    assertTrue("expected at least one matched edge", edges!!.isNotEmpty())
    assertNotNull("expected the matched shape", response.shape)
  }

  @Test
  fun test_traceAttributes_filtered() {
    val request =
        TraceAttributesRequest(
            encodedPolyline = routeShape(),
            costing = MapMatchCostingModel.auto,
            filters =
                TraceAttributeFilterOptions(
                    attributes =
                        listOf(
                            TraceAttributeKey.edgePeriodSpeed, TraceAttributeKey.edgePeriodNames),
                    action = TraceAttributeFilterOptions.Action.include))

    val response = valhalla.traceAttributes(request)

    val edges = response.edges
    assertNotNull("expected matched edges", edges)
    assertTrue("expected at least one matched edge", edges!!.isNotEmpty())
    // Only the requested attributes come back; the shape was not among them.
    assertEquals(null, response.shape)
  }

  @Test
  fun test_traceAttributes_noSuitableEdges() {
    val request =
        TraceAttributesRequest(
            shape =
                listOf(
                    MapMatchWaypoint(lat = 45.843812, lon = -123.768205),
                    MapMatchWaypoint(lat = 45.869701, lon = -123.766121)),
            costing = MapMatchCostingModel.auto)

    val exception =
        assertThrows(ValhallaException::class.java) { valhalla.traceAttributes(request) }

    assertTrue(
        "expected a Valhalla error, got: ${exception.message}",
        exception is ValhallaException.Internal)
  }

  /** Encoded polylines contain backslashes, so they cannot be pasted into JSON unescaped. */
  private fun quote(value: String): String {
    val escaped = value.replace("\\", "\\\\").replace("\"", "\\\"")
    return "\"$escaped\""
  }
}
