package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.config.ValhallaConfigBuilder
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Exercises [Valhalla.matrixRaw] against the bundled Andorra tile extract.
 *
 * There is no generated `MatrixRequest`/`MatrixResponse` model yet, so — unlike the other
 * actions — this one is reached only through the raw JSON escape hatch. See the comment on
 * [Valhalla.matrixRaw] itself.
 */
@RunWith(AndroidJUnit4::class)
class ValhallaMatrixTest {

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

  @After
  fun tearDown() {
    valhalla.close()
  }

  @Test
  fun testSuccessfulMatrix() {
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

    val response = JSONObject(valhalla.matrixRaw(request))
    val sourcesToTargets = response.getJSONArray("sources_to_targets")

    assertEquals(2, sourcesToTargets.length())
    assertTrue(
        "expected a real distance in: $response",
        sourcesToTargets.getJSONArray(0).getJSONObject(0).getDouble("distance") > 0)
  }

  @Test
  fun testMatrixWithBadCostingThrows() {
    val request =
        JSONObject()
            .put(
                "sources", JSONArray().put(JSONObject().put("lat", 42.5063).put("lon", 1.5218)))
            .put(
                "targets", JSONArray().put(JSONObject().put("lat", 42.5086).put("lon", 1.5394)))
            .put("costing", "not-a-real-costing-model")
            .toString()

    assertThrows(ValhallaException.Internal::class.java) { valhalla.matrixRaw(request) }
  }
}
