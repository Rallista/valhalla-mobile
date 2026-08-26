package com.valhalla.valhalla

import android.content.Context
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ValhallaActorTest {

  private lateinit var appContext: Context
  private lateinit var configPath: String
  private val actors = mutableListOf<ValhallaActor>()

  @Before
  fun setUp() {
    appContext = InstrumentationRegistry.getInstrumentation().targetContext
    configPath = TestFileUtils.getConfigPath(appContext)
    Log.d("ValhallaActorTest", "Using config path: $configPath")
  }

  /**
   * Build an actor and hold it for teardown. The native actor now lives as long as the Kotlin
   * object, so every test has to release it or the tile extract stays mapped.
   */
  private fun actor(configPath: String): ValhallaActor =
      ValhallaActor(configPath).also { actors += it }

  @After
  fun tearDown() {
    actors.forEach { it.close() }
    actors.clear()
  }

  @Test
  fun testNoConfigPath() {
    val valhalla = actor("invalid.json")

    val request =
        "{\"locations\":[{\"lat\":45.843812,\"lon\":-123.768205},{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\",\"units\":\"miles\"}"
    val response = valhalla.route(request)

    assertEquals(response, "{\"code\":-1,\"message\":\"Cannot open file invalid.json\"}")
  }

  @Test
  fun testNoSuitableEdges() {
    val valhalla = actor(configPath)

    val request =
        "{\"locations\":[{\"lat\":45.843812,\"lon\":-123.768205},{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\",\"units\":\"miles\"}"
    val response = valhalla.route(request)

    assertEquals(response, "{\"code\":171,\"message\":\"No suitable edges near location\"}")
  }

  @Test
  fun testSuccessfulRoute() {
    val valhalla = actor(configPath)

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
    val valhalla = actor(configPath)

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

  /**
   * The trace is the exact shape of a prior route, so Valhalla walks the edges instead of running
   * Meili, and there are no matched_points — [testMapSnapTraceAttributes] covers those.
   */
  @Test
  fun testSuccessfulTraceAttributes() {
    val valhalla = actor(configPath)

    val request =
        JSONObject()
            .put("encoded_polyline", routeShape(valhalla))
            .put("costing", "auto")
            .toString()
    val response = valhalla.traceAttributes(request)

    val responseJson = JSONObject(response)

    assertTrue(
        "expected matched edges in: $response", responseJson.getJSONArray("edges").length() > 0)
    assertFalse("expected no matched points in: $response", responseJson.has("matched_points"))
  }

  /** The map-snapping path is the one that reports how each input point matched. */
  @Test
  fun testMapSnapTraceAttributes() {
    val valhalla = actor(configPath)

    val request =
        JSONObject()
            .put("encoded_polyline", routeShape(valhalla))
            .put("costing", "auto")
            .put("shape_match", "map_snap")
            .toString()
    val response = valhalla.traceAttributes(request)

    val responseJson = JSONObject(response)

    assertTrue(
        "expected matched points in: $response",
        responseJson.getJSONArray("matched_points").length() > 0)
  }

  /** The trace actions report failures through the same envelope [route] does. */
  @Test
  fun testTraceRouteNoConfigPath() {
    val valhalla = actor("invalid.json")

    val request = "{\"encoded_polyline\":\"abc\",\"costing\":\"auto\"}"
    val response = valhalla.traceRoute(request)

    assertEquals(response, "{\"code\":-1,\"message\":\"Cannot open file invalid.json\"}")
  }

  @Test
  fun testTraceAttributesNoConfigPath() {
    val valhalla = actor("invalid.json")

    val request = "{\"encoded_polyline\":\"abc\",\"costing\":\"auto\"}"
    val response = valhalla.traceAttributes(request)

    assertEquals(response, "{\"code\":-1,\"message\":\"Cannot open file invalid.json\"}")
  }

  /**
   * Validate that caller text in an error message cannot break the payload.
   *
   * Valhalla quotes an unknown costing name back to the caller in error 125
   * (src/valhalla/src/worker.cc:823). The wrapper must escape that message. Without the escape the
   * payload is not valid JSON, the error parse fails, and the real error is lost.
   */
  @Test
  fun testErrorMessageEscapesCallerText() {
    val valhalla = actor(configPath)

    // A costing name with the three characters that broke the payload.
    val costingName = "auto\"\\\nevil"

    val locations =
        JSONArray().apply {
          put(
              JSONObject().apply {
                put("lat", 42.5063)
                put("lon", 1.5218)
              })
          put(
              JSONObject().apply {
                put("lat", 42.5086)
                put("lon", 1.5394)
              })
        }
    val request =
        JSONObject()
            .apply {
              put("locations", locations)
              put("costing", costingName)
              put("units", "miles")
            }
            .toString()

    val response = valhalla.route(request)

    // The constructor throws if the wrapper did not escape the message.
    val json = JSONObject(response)

    assertEquals(125, json.getInt("code"))
    assertTrue(
        "the message must carry the costing name unchanged, got: ${json.getString("message")}",
        json.getString("message").contains(costingName))
  }

  private val andorraRoute =
      "{\"locations\":[{\"lat\":42.5063,\"lon\":1.5218},{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\",\"units\":\"miles\"}"

  @Test
  fun testSuccessfulMatrix() {
    val valhalla = actor(configPath)

    val request =
        JSONObject()
            .put(
                "sources",
                JSONArray()
                    .put(JSONObject().put("lat", 42.5063).put("lon", 1.5218))
                    .put(JSONObject().put("lat", 42.5086).put("lon", 1.5394)))
            .put(
                "targets",
                JSONArray().put(JSONObject().put("lat", 42.5086).put("lon", 1.5394)))
            .put("costing", "auto")
            .toString()
    val response = valhalla.matrix(request)

    val sourcesToTargets = JSONObject(response).getJSONArray("sources_to_targets")
    assertEquals(2, sourcesToTargets.length())
    val firstRow = sourcesToTargets.getJSONArray(0)
    assertEquals(1, firstRow.length())
    val cell = firstRow.getJSONObject(0)
    assertTrue("expected a real distance in: $response", cell.getDouble("distance") > 0)
    // The second source is the target itself, so that row costs nothing.
    val secondRow = sourcesToTargets.getJSONArray(1)
    assertEquals(0.0, secondRow.getJSONObject(0).getDouble("distance"), 0.0)
  }

  @Test
  fun testMatrixNoConfigPath() {
    val valhalla = actor("invalid.json")

    val request =
        "{\"sources\":[{\"lat\":45.843812,\"lon\":-123.768205}],\"targets\":[{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\"}"
    val response = valhalla.matrix(request)

    assertEquals(response, "{\"code\":-1,\"message\":\"Cannot open file invalid.json\"}")
  }

  @Test
  fun testMatrixNoSuitableEdges() {
    val valhalla = actor(configPath)

    val request =
        "{\"sources\":[{\"lat\":45.843812,\"lon\":-123.768205}],\"targets\":[{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\"}"
    val response = valhalla.matrix(request)

    assertEquals(response, "{\"code\":171,\"message\":\"No suitable edges near location\"}")
  }

  /** A character outside the BMP has to survive both crossings of the bridge. */
  @Test
  fun testFourByteCharacterSurvivesTheBridge() {
    val valhalla = actor(configPath)

    val request = andorraRoute.replace("\"costing\":\"auto\"", "\"costing\":\"auto😀\"")
    val json = JSONObject(valhalla.route(request))

    assertEquals(125, json.getInt("code"))
    assertTrue(json.getString("message").contains("auto😀"))
  }

  /** A pbf response is protobuf bytes, not UTF-8, so the bridge must answer an error, not abort. */
  @Test
  fun testBinaryResponseIsReportedAsError() {
    val valhalla = actor(configPath)

    val response = valhalla.route(andorraRoute.replace("\"units\":\"miles\"", "\"format\":\"pbf\""))

    assertEquals("{\"code\":-1,\"message\":\"response was not valid UTF-8\"}", response)
  }

  /** A closed actor must refuse work rather than dereference the freed handle. */
  @Test
  fun testUseAfterCloseThrows() {
    val valhalla = actor(configPath)
    valhalla.close()

    assertThrows(IllegalStateException::class.java) { valhalla.route(andorraRoute) }
    assertThrows(IllegalStateException::class.java) { valhalla.traceRoute(andorraRoute) }
    assertThrows(IllegalStateException::class.java) { valhalla.traceAttributes(andorraRoute) }
    assertThrows(IllegalStateException::class.java) {
      valhalla.matrix(
          "{\"sources\":[{\"lat\":42.5063,\"lon\":1.5218}],\"targets\":[{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\"}")
    }
  }

  /** Teardown closes every actor, so closing one twice has to be harmless. */
  @Test
  fun testCloseIsIdempotent() {
    val valhalla = actor(configPath)

    valhalla.close()
    valhalla.close()
  }
}
