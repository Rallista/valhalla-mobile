package com.valhalla.valhalla

import android.content.Context
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
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
   * Validate that caller text in an error message cannot break the payload.
   *
   * Valhalla quotes an unknown costing name back to the caller in error 125
   * (src/valhalla/src/worker.cc:823). The wrapper must escape that message. Without the escape the
   * payload is not valid JSON, the error parse fails, and the real error is lost.
   */
  @Test
  fun testErrorMessageEscapesCallerText() {
    val valhalla = ValhallaActor(configPath)

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
}
