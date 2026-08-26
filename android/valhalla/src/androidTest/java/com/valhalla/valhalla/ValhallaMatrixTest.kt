package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.api.models.Coordinate
import com.valhalla.api.models.MatrixCostingModel
import com.valhalla.api.models.MatrixRequest
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
import org.junit.Ignore
import org.junit.Test
import org.junit.runner.RunWith

/** Exercises [Valhalla.matrix] and [Valhalla.matrixRaw] against the bundled Andorra tile extract. */
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

  // The currently-pinned valhalla-models (0.5.0) models MatrixResponse.sources/targets as
  // List<List<Coordinate>>, but Valhalla actually returns them flat - decoding a real response
  // throws. Fixed upstream in Rallista/valhalla-openapi-models-kotlin#29; re-enable once a
  // models release with that fix is out and this repo's dependency is bumped to it.
  @Ignore("blocked on valhalla-openapi-models-kotlin#29")
  @Test
  fun testSuccessfulTypedMatrix() {
    val request =
        MatrixRequest(
            sources =
                listOf(
                    Coordinate(lat = 42.5063, lon = 1.5218),
                    Coordinate(lat = 42.5086, lon = 1.5394)),
            targets = listOf(Coordinate(lat = 42.5086, lon = 1.5394)),
            costing = MatrixCostingModel.auto)

    val response = valhalla.matrix(request)

    assertEquals(2, response.sourcesToTargets.size)
    assertTrue(
        "expected a real distance in: $response",
        response.sourcesToTargets[0][0].distance > 0)
    // The second source is the target itself, so that row costs nothing.
    assertEquals(0.0, response.sourcesToTargets[1][0].distance, 0.0)
  }

  @Test
  fun testTypedMatrixWithNoSuitableEdgesThrows() {
    val request =
        MatrixRequest(
            sources = listOf(Coordinate(lat = 45.843812, lon = -123.768205)),
            targets = listOf(Coordinate(lat = 45.869701, lon = -123.766121)),
            costing = MatrixCostingModel.auto)

    assertThrows(ValhallaException.Internal::class.java) { valhalla.matrix(request) }
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
