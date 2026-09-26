package com.valhalla.valhalla

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.valhalla.valhalla.config.ValhallaConfigFactory
import com.valhalla.valhalla.config.ValhallaConfigManager
import com.valhalla.valhalla.files.ValhallaFile
import com.valhalla.valhalla.http.ValhallaHttpResponse
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/** What an action does when a tile fetch fails, runs past the deadline, or is cancelled. */
@RunWith(AndroidJUnit4::class)
class ValhallaTileFetchTest {

  private lateinit var context: Context
  private lateinit var tilesDir: File
  private lateinit var client: FakeTileClient
  private val actors = mutableListOf<ValhallaActor>()

  @Before
  fun setUp() {
    context = InstrumentationRegistry.getInstrumentation().targetContext
    tilesDir = File(context.cacheDir, "tile-fetch-${UUID.randomUUID()}").apply { mkdirs() }
    client = FakeTileClient(context.assets)
  }

  @After
  fun tearDown() {
    actors.forEach { it.close() }
    if (::tilesDir.isInitialized) tilesDir.deleteRecursively()
  }

  private fun actor(timeoutSeconds: Double = 0.0): ValhallaActor {
    val config =
        ValhallaConfigFactory.usingTileUrl("${FakeTileClient.BASE_URL}{tilePath}", tilesDir.absolutePath)
    val file = ValhallaFile(context, "tile-fetch.json")
    ValhallaConfigManager(context, file).writeConfig(config)
    // The config models have no field for the timeout, so it goes into the written JSON.
    val written = File(file.absolutePath())
    val json = JSONObject(written.readText())
    json.getJSONObject("mjolnir").put("tile_url_timeout", timeoutSeconds)
    written.writeText(json.toString())
    return ValhallaActor(file.absolutePath(), client).also { actors += it }
  }

  /** Routes, and returns the trip's status message, or the error's message. */
  private fun ValhallaActor.routeStatus(): String {
    val response = JSONObject(route(ANDORRA_ROUTE))
    return response.optJSONObject("trip")?.getString("status_message")
        ?: response.getString("message")
  }

  @Test
  fun testFailedFetchFailsTheActionAndTheNextRetriesIt() {
    client.answer = { ValhallaHttpResponse.failure(503) }
    val actor = actor()

    // Not loki's "No suitable edges near location", which would blame the locations.
    assertEquals(FETCH_FAILED, actor.routeStatus())

    client.answer = { null }
    assertEquals(FOUND, actor.routeStatus())
  }

  @Test
  fun testMissingTileIsNotRetried() {
    client.answer = { ValhallaHttpResponse.failure(404) }
    val actor = actor()

    assertEquals(NO_EDGES, actor.routeStatus())
    val requests = client.requests.size

    client.answer = { null }
    assertEquals(NO_EDGES, actor.routeStatus())
    assertEquals(requests, client.requests.size)
  }

  @Test
  fun testDeadlineStopsTheActionBeforeItsNextFetch() {
    client.answer = {
      Thread.sleep(1_500)
      null
    }
    val actor = actor(timeoutSeconds = 1.0)

    assertEquals(TIMED_OUT, actor.routeStatus())
    // The fetch in flight as the deadline passed finished, and the next was never sent.
    assertEquals(1, client.requests.size)

    // Each action gets its own deadline.
    client.answer = { null }
    assertEquals(FOUND, actor.routeStatus())
  }

  /** An actor on the bundled tile extract, which fetches nothing. */
  private fun extractActor(timeoutSeconds: Double = 0.0): ValhallaActor {
    val json = JSONObject(File(TestFileUtils.getConfigPath(context)).readText())
    json.getJSONObject("mjolnir").put("tile_url_timeout", timeoutSeconds)
    val file = File(tilesDir, "extract.json").apply { writeText(json.toString()) }
    return ValhallaActor(file.absolutePath, client).also { actors += it }
  }

  @Test
  fun testDeadlineDoesNotStopAPathSearch() {
    // Thor runs the action's interrupt on a matrix's first step, long after this deadline.
    val response = JSONObject(extractActor(timeoutSeconds = 1e-9).matrix(ANDORRA_MATRIX))

    assertTrue(response.toString(), response.has("sources_to_targets"))
  }

  @Test
  fun testCancelStopsAPathSearch() {
    val actor = extractActor()

    actor.cancel()
    assertEquals(CANCELLED, JSONObject(actor.matrix(ANDORRA_MATRIX)).getString("message"))

    actor.resume()
    assertTrue(JSONObject(actor.matrix(ANDORRA_MATRIX)).has("sources_to_targets"))
  }

  @Test
  fun testCancelStopsARunningActionUntilResumed() {
    val fetching = CountDownLatch(1)
    val release = CountDownLatch(1)
    client.answer = {
      fetching.countDown()
      release.await(10, TimeUnit.SECONDS)
      null
    }
    val actor = actor()
    val executor = Executors.newSingleThreadExecutor()
    try {
      val running = executor.submit<String> { actor.routeStatus() }
      assertTrue(fetching.await(10, TimeUnit.SECONDS))

      // The action holds the actor's lock for as long as it runs, and cancel must not wait for it.
      actor.cancel()
      release.countDown()
      assertEquals(CANCELLED, running.get(10, TimeUnit.SECONDS))
    } finally {
      executor.shutdown()
    }

    // A cancel lasts until resume.
    client.answer = { null }
    assertEquals(CANCELLED, actor.routeStatus())

    actor.resume()
    assertEquals(FOUND, actor.routeStatus())
  }

  private companion object {
    const val FOUND = "Found route between points"
    const val NO_EDGES = "No suitable edges near location"
    const val FETCH_FAILED = "valhalla-mobile: tile fetch failed"
    const val TIMED_OUT = "valhalla-mobile: tile fetch deadline"
    const val CANCELLED = "valhalla-mobile: cancelled"
    const val ANDORRA_MATRIX =
        "{\"sources\":[{\"lat\":42.5063,\"lon\":1.5218}],\"targets\":[{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\"}"
    const val ANDORRA_ROUTE =
        "{\"locations\":[{\"lat\":42.5063,\"lon\":1.5218},{\"lat\":42.5086,\"lon\":1.5394}],\"costing\":\"auto\",\"units\":\"miles\"}"
  }
}
