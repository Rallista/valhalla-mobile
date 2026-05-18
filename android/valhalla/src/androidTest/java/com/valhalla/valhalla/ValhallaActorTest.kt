package com.valhalla.valhalla

import android.content.Context
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertThrows
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
  fun testNoConfigPath_throwsAtConstruction() {
    // Construction is eager: an unreadable config fails fast rather than
    // surfacing the same error on every subsequent request.
    val exception =
        assertThrows(ValhallaException.Internal::class.java) { ValhallaActor("invalid.json") }
    assertNotNull(exception.message)
    // The C++ message ("Cannot open file invalid.json") is carried through
    // the native -> JVM bridge unchanged.
    assert(exception.message!!.contains("Cannot open file invalid.json")) {
      "Expected exception message to contain native error, got: ${exception.message}"
    }
  }

  @Test
  fun testNoSuitableEdges() {
    ValhallaActor(configPath).use { valhalla ->
      val request =
          "{\"locations\":[{\"lat\":45.843812,\"lon\":-123.768205},{\"lat\":45.869701,\"lon\":-123.766121}],\"costing\":\"auto\",\"units\":\"miles\"}"
      val response = valhalla.route(request)

      assertEquals("{\"code\":171,\"message\":\"No suitable edges near location\"}", response)
    }
  }

  @Test
  fun testSuccessfulRoute() {
    ValhallaActor(configPath).use { valhalla ->
      val request =
          "{\"locations\":[{\"lat\":42.5063,\"lon\":1.5218},{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\",\"units\":\"miles\"}"
      val response = valhalla.route(request)

      val responseJson = JSONObject(response)
      val trip = responseJson.getJSONObject("trip")

      assertEquals(0, trip.getInt("status"))
      assertEquals("Found route between points", trip.getString("status_message"))
    }
  }

  @Test
  fun testRouteAfterCloseThrows() {
    val valhalla = ValhallaActor(configPath)
    valhalla.close()

    val request =
        "{\"locations\":[{\"lat\":42.5063,\"lon\":1.5218},{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\"}"
    assertThrows(IllegalStateException::class.java) { valhalla.route(request) }
  }

  @Test
  fun testCloseIsIdempotent() {
    val valhalla = ValhallaActor(configPath)
    valhalla.close()
    // Second close should be a no-op, not a crash.
    valhalla.close()
  }
}
