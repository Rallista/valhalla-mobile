Package com.valhalla.valhalla

A wrapper for Valhalla's actor. This is the core object that accepts a valid valhalla config
and allows fetching routes from valid valhalla tiles.

> `route` blocks while the native engine works, so call it off the main thread.

```kt
val tilesDir = appContext.getExternalFilesDir()
val tarFile = ValhallaFile(appContext, "valhalla_tiles.tar", tilesDir!!)
// Alternatively, for a tile extract bundled in the APK:
// val tarFile = ValhallaFile.usingAsset(appContext, "valhalla_tiles.tar")

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

## Response formats

`route` returns a `ValhallaResponse` sealed class that mirrors the `RouteRequest.Format`
you asked for.
The default is `RouteRequest.Format.json`, Valhalla's own response shape:

```kt
when (val response = valhalla.route(request)) {
    is ValhallaResponse.Json -> {
        val trip = response.jsonResponse.trip
        // trip.status, trip.summary, trip.legs[i].shape (encoded polyline, precision 1e6)
    }
    is ValhallaResponse.Osrm -> { /* Only when format = RouteRequest.Format.osrm. */ }
}
```

`RouteRequest.Format.gpx` and `RouteRequest.Format.pbf` are not supported and throw
`ValhallaException.NotSupported`.

## Error handling

`route` throws a `ValhallaException` subclass on failure:

- `ValhallaException.Internal` wraps an error the routing engine itself returned, for example
  `ValhallaError(code=171, No suitable edges near location)`. The codes are documented in
  [Valhalla's internal error reference](https://valhalla.github.io/valhalla/api/turn-by-turn/api-reference/#internal-error-codes-and-conditions).
- `ValhallaException.InvalidResponse` and `ValhallaException.InvalidError` mean the response,
  or the error inside it, could not be parsed.
- `ValhallaException.NotSupported` means the requested format is not implemented yet.
