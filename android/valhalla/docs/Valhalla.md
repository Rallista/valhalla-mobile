Package com.valhalla.valhalla

A wrapper for Valhalla's actor. This is the core object that accepts a valid valhalla config
and allows fetching routes from valid valhalla tiles.

```kt
val tilesDir = appContext.getExternalFilesDir()
val tarFile = ValhallaFile(appContext, "valhalla_tiles.tar", tilesDir!!)
val config = ValhallaConfigBuilder()
    .withTileExtract(tarFile.absolutePath())
    .build()

// Create the Valhalla instance
val valhalla = Valhalla(appContext, config)

// Create a valhalla request.
val request =
    RouteRequest(
        locations =
            listOf(
                RoutingWaypoint(lat = 38.429719, lon = -108.827425),
                RoutingWaypoint(lat = 38.4604331, lon = -108.8817009)),
        costing = CostingModel.auto)

// Fetch a route from Valhalla
val response = valhalla.route(request)
```
