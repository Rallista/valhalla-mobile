package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.api.models.CostingModel
import com.valhalla.config.ValhallaConfigBuilder
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import com.valhalla.valhalla.mapmatching.FilterAction
import com.valhalla.valhalla.mapmatching.ShapeMatch
import com.valhalla.valhalla.mapmatching.TraceAttributesRequest
import com.valhalla.valhalla.mapmatching.TraceFilters
import com.valhalla.valhalla.mapmatching.TraceOptions
import com.valhalla.valhalla.mapmatching.TracePoint
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end smoke test for on-device Meili map matching via Valhalla's `trace_attributes` action.
 * Uses the bundled Andorra (`valhalla_tiles.tar`) fixture.
 *
 * The endpoints (42.5063, 1.5218) and (42.5086, 1.5394) are the same as the routing tests, which
 * proves they sit on the road graph. We use a generous 120s gap so the inferred speed (~12 m/s ≈ 44
 * km/h) is plausible — Meili's `max_route_time_factor` rejects implausibly fast transitions.
 */
@RunWith(AndroidJUnit4::class)
class ValhallaTraceAttributesTest {

  private lateinit var appContext: Context
  private lateinit var valhalla: Valhalla

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext
    val configManager = ValhallaConfigManager(appContext)

    val tarFile = ValhallaFile.usingAsset(appContext, "valhalla_tiles.tar")
    val config = ValhallaConfigBuilder().withTileExtract(tarFile.absolutePath()).build()

    valhalla = Valhalla(appContext, config, configManager)
  }

  @After
  fun tearDown() {
    valhalla.close()
  }

  @Test
  fun matchesTraceAlongAndorranRoad() {
    val shape =
        listOf(
            TracePoint(lat = 42.5063, lon = 1.5218, time = 0.0, accuracy = 10.0),
            TracePoint(lat = 42.5086, lon = 1.5394, time = 120.0, accuracy = 10.0),
        )
    val request =
        TraceAttributesRequest(
            shape = shape,
            costing = CostingModel.auto,
            shapeMatch = ShapeMatch.MAP_SNAP,
            filters =
                TraceFilters(
                    attributes =
                        listOf(
                            "matched.point",
                            "matched.type",
                            "matched.distance_along_edge",
                            "matched.edge_index",
                            "edge.way_id",
                            "edge.length",
                            "edge.begin_shape_index",
                            "edge.end_shape_index",
                        ),
                    action = FilterAction.INCLUDE,
                ),
            traceOptions =
                TraceOptions(
                    searchRadius = 100.0,
                    gpsAccuracy = 15.0,
                    breakageDistance = 5000.0,
                    maxRouteDistanceFactor = 10.0,
                    maxRouteTimeFactor = 10.0,
                ),
        )

    val rawResponse = valhalla.traceAttributes(request)
    val json = JSONObject(rawResponse)

    val matchedPoints = json.optJSONArray("matched_points")
    assertNotNull("response should include matched_points array", matchedPoints)
    assertEquals(
        "matched_points length should equal shape length", shape.size, matchedPoints!!.length())

    val edges = json.optJSONArray("edges")
    assertNotNull("response should include edges array", edges)
    assertTrue("response should match at least one edge", edges!!.length() > 0)

    // Validate the first matched point sits close to its source measurement.
    // ~0.001 degree is about 100m near Andorra's latitude; well within reason
    // for a real road snap.
    val firstMatch = matchedPoints.getJSONObject(0)
    val dLat = firstMatch.getDouble("lat") - shape[0].lat
    val dLon = firstMatch.getDouble("lon") - shape[0].lon
    assertTrue(
        "first matched point should be within ~100m of its measurement, got dLat=$dLat dLon=$dLon",
        kotlin.math.abs(dLat) < 0.001 && kotlin.math.abs(dLon) < 0.001,
    )
  }

  @Test
  fun invalidShapeReturnsValhallaError() {
    // Two points in the Pacific Ocean — no graph data exists.
    val request =
        TraceAttributesRequest(
            shape =
                listOf(
                    TracePoint(lat = 0.0, lon = -150.0, time = 0.0),
                    TracePoint(lat = 0.0, lon = -149.9, time = 60.0),
                ),
            costing = CostingModel.auto,
        )

    assertThrows(ValhallaException.Internal::class.java) { valhalla.traceAttributes(request) }
  }

  @Test
  fun rawRequestEscapeHatchWorks() {
    // Same coordinates as the success test, but built by hand.
    val rawRequest =
        """
        {
          "shape": [
            {"lat": 42.5063, "lon": 1.5218, "time": 0},
            {"lat": 42.5086, "lon": 1.5394, "time": 120}
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

    val rawResponse = valhalla.traceAttributesRaw(rawRequest)
    val json = JSONObject(rawResponse)
    assertNotNull(json.optJSONArray("matched_points"))
  }
}
