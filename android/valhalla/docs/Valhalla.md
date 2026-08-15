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

## Map matching

The same instance also snaps a recorded GPS trace onto the road network, against the tiles already on
the device. Supply the trace either as a list of `MapMatchWaypoint`s or as an encoded polyline — note
that the polyline must use six digits of precision rather than the usual five.

Use `traceRoute` when you want a route along the matched path:

```kt
val response = valhalla.traceRoute(
    MapMatchRequest(
        shape =
            listOf(
                MapMatchWaypoint(lat = 42.5063, lon = 1.5218),
                MapMatchWaypoint(lat = 42.5074, lon = 1.5301),
                MapMatchWaypoint(lat = 42.5086, lon = 1.5394)),
        costing = MapMatchCostingModel.auto))

println(response.trip.statusMessage)
```

Use `traceAttributes` when you want the road network itself — edge identifiers, road classes, speeds,
names — rather than turn by turn directions. Narrow the response with `filters`; by default valhalla
returns every attribute it has, which is a lot of JSON for a long trace:

```kt
val response = valhalla.traceAttributes(
    TraceAttributesRequest(
        encodedPolyline = polyline6,
        costing = MapMatchCostingModel.auto,
        filters =
            TraceAttributeFilterOptions(
                attributes = listOf(TraceAttributeKey.edgePeriodSpeed, TraceAttributeKey.edgePeriodNames),
                action = TraceAttributeFilterOptions.Action.include)))

response.edges?.forEach { println(it.names) }
```

Both actions report engine failures — including a trace that cannot be matched — as
`ValhallaException.Internal`. Formats other than valhalla's own JSON are reachable through
`traceRouteRaw` and `traceAttributesRaw`, which return the response body unparsed.
