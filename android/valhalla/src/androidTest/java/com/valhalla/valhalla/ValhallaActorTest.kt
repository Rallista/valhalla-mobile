package com.valhalla.valhalla

import android.content.Context
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ValhallaActorTest {

  private lateinit var appContext: Context
  private lateinit var configPath: String

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext
    configPath = TestFileUtils.getConfigPath(appContext)
    Log.d("ValhallaActorTest", "Using config path: $configPath")
  }

  @Test
  fun testNoConfigPath() {
    val valhalla = ValhallaActor("invalid.json")

    val request =
        "{\"locations\":[{\"lat\":45.843812,\"lon\":-123.768205},{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\",\"units\":\"miles\"}"
    val response = valhalla.route(request)

    assertEquals(response, "{\"code\":-1,\"message\":\"Cannot open file invalid.json\"}")
  }

  @Test
  fun testNoSuitableEdges() {
    val valhalla = ValhallaActor(configPath)

    val request =
        "{\"locations\":[{\"lat\":45.843812,\"lon\":-123.768205},{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\",\"units\":\"miles\"}"
    val response = valhalla.route(request)

    assertEquals(response, "{\"code\":171,\"message\":\"No suitable edges near location\"}")
  }

  @Test
  fun testSuccessfulRoute() {
    val valhalla = ValhallaActor(configPath)

    val request =
        "{\"locations\":[{\"lat\":42.5063,\"lon\":1.5218},{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\",\"units\":\"miles\"}"
    val response = valhalla.route(request)

    val responseJson = JSONObject(response)
    val trip = responseJson.getJSONObject("trip")

    assertEquals(0, trip.getInt("status"))
    assertEquals("Found route between points", trip.getString("status_message"))
  }

  /**
   * The shape of a known-good route through the fixture, taken from the engine itself so that the
   * trace assertions below are about map matching rather than about how well some hand-picked
   * coordinates happen to sit on an Andorran road.
   */
  private fun routeShape(valhalla: ValhallaActor): String {
    val request =
        "{\"locations\":[{\"lat\":42.5063,\"lon\":1.5218},{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\",\"units\":\"miles\"}"
    val trip = JSONObject(valhalla.route(request)).getJSONObject("trip")

    return trip.getJSONArray("legs").getJSONObject(0).getString("shape")
  }

  @Test
  fun testSuccessfulTraceRoute() {
    val valhalla = ValhallaActor(configPath)

    val request =
        JSONObject()
            .put("encoded_polyline", routeShape(valhalla))
            .put("costing", "auto")
            .toString()
    val response = valhalla.traceRoute(request)

    val trip = JSONObject(response).getJSONObject("trip")

    assertEquals(0, trip.getInt("status"))
    assertEquals("Found route between points", trip.getString("status_message"))
  }

  @Test
  fun testSuccessfulTraceAttributes() {
    val valhalla = ValhallaActor(configPath)

    val request =
        JSONObject()
            .put("encoded_polyline", routeShape(valhalla))
            .put("costing", "auto")
            .toString()
    val response = valhalla.traceAttributes(request)

    val responseJson = JSONObject(response)

    assertTrue(
        "expected matched edges in: $response", responseJson.getJSONArray("edges").length() > 0)
    assertTrue(
        "expected matched points in: $response",
        responseJson.getJSONArray("matched_points").length() > 0)
  }

  /** The trace actions report failures through the same envelope [route] does. */
  @Test
  fun testTraceRouteNoConfigPath() {
    val valhalla = ValhallaActor("invalid.json")

    val request = "{\"encoded_polyline\":\"abc\",\"costing\":\"auto\"}"
    val response = valhalla.traceRoute(request)

    assertEquals(response, "{\"code\":-1,\"message\":\"Cannot open file invalid.json\"}")
  }

  @Test
  fun testTraceAttributesNoConfigPath() {
    val valhalla = ValhallaActor("invalid.json")

    val request = "{\"encoded_polyline\":\"abc\",\"costing\":\"auto\"}"
    val response = valhalla.traceAttributes(request)

    assertEquals(response, "{\"code\":-1,\"message\":\"Cannot open file invalid.json\"}")
  }
}
