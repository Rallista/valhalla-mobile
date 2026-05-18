# On-device map matching

Starting with version 0.6.0,
the Android library exposes Valhalla's `trace_attributes` action,
which runs the Meili HMM map matcher entirely on-device.
This is useful for navigation clients that need to disambiguate
parallel roads, divided carriageways, or interchanges —
cases where heuristic snap-to-polyline reaches its ceiling.

## Prerequisites

- A Valhalla tile extract (`valhalla_tiles.tar`)
  available on the device's filesystem.
- The same `mjolnir.tile_extract` path in the Valhalla config.
- A typical corridor tar for a single route is 6–17 MB.

## Building a request

```kotlin
import com.valhalla.valhalla.Valhalla
import com.valhalla.valhalla.mapmatching.TraceAttributesRequest
import com.valhalla.valhalla.mapmatching.TraceFilters
import com.valhalla.valhalla.mapmatching.TraceOptions
import com.valhalla.valhalla.mapmatching.TracePoint
import com.valhalla.valhalla.mapmatching.ShapeMatch
import com.valhalla.valhalla.mapmatching.FilterAction

val request = TraceAttributesRequest(
    shape = gpsSamples.map { sample ->
        TracePoint(
            lat = sample.latitude,
            lon = sample.longitude,
            time = sample.epochSeconds,
            accuracy = sample.horizontalAccuracyMeters,
        )
    },
    costing = "auto",
    shapeMatch = ShapeMatch.MAP_SNAP,
    filters = TraceFilters(
        attributes = listOf(
            "matched.point",
            "matched.type",
            "matched.distance_along_edge",
            "matched.edge_index",
            "edge.way_id",
            "edge.length",
            "edge.begin_heading",
            "edge.end_heading",
            "edge.speed",
        ),
        action = FilterAction.INCLUDE,
    ),
    traceOptions = TraceOptions(
        searchRadius = 50.0,
        gpsAccuracy = 10.0,
    ),
)
```

## Calling the matcher

```kotlin
Valhalla(context, config).use { valhalla ->
    val responseJson = valhalla.traceAttributes(request)
    // Decode with whatever model fits your consumer.
}
```

The library returns the raw JSON
because the response shape varies with the requested attributes
and most consumers only need a subset of fields.
Use Moshi, kotlinx.serialization, or any other parser to decode.

## Response shape

Top-level fields you typically care about:

| Field              | Type    | Description                                              |
| ------------------ | ------- | -------------------------------------------------------- |
| `matched_points`   | array   | One per input GPS point. Has `lat`, `lon`, `type`, `distance_along_edge`, `edge_index`. `type` is one of `matched`, `interpolated`, `unmatched`. |
| `edges`            | array   | The matched edges along the trace. Fields depend on the request's attribute filters. |
| `admins`           | array   | Administrative regions touched by the matched path.      |
| `units`            | string  | `"kilometers"` (default) or `"miles"`.                   |
| `shape`            | string  | Polyline6-encoded matched path.                          |

Errors come back as
`{"code": <int>, "message": "..."}`.
The library wraps these into `ValhallaException.Internal`
so they are thrown rather than returned.

## Lifecycle

`Valhalla` now implements `Closeable`.
The native actor (and its memory-mapped tile extract)
is held for the lifetime of the instance.
Always close it when done —
either with Kotlin's `use { }`
or by calling `close()` explicitly.

Calling any method after `close()` throws `IllegalStateException`.

## Off-route detection

The most common navigation use case
is detecting whether the user has deviated from the planned route.
With the matched-edge ID returned per GPS point,
this becomes a single graph lookup:

```kotlin
val plannedEdgeIds: Set<Long> = computePlannedEdgeIds()
val responseJson = valhalla.traceAttributes(request)
val matchedEdgeIds = parseMatchedEdges(responseJson)
val onRoute = matchedEdgeIds.any { it in plannedEdgeIds }
```

Replaces the heuristic distance / bearing / hysteresis stack
with a deterministic check.
