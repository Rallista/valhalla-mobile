# Valhalla Mobile

[![Valhalla](https://img.shields.io/badge/Valhalla-3.6.3-blue)](https://github.com/valhalla/valhalla/releases/tag/3.6.3)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRallista%2Fvalhalla-mobile%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Rallista/valhalla-mobile)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRallista%2Fvalhalla-mobile%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Rallista/valhalla-mobile)
[![Maven Central](https://img.shields.io/maven-central/v/io.github.rallista/valhalla-mobile)](https://central.sonatype.com/artifact/io.github.rallista/valhalla-mobile)
[![Kotlin Docs](https://img.shields.io/badge/Kotlin%20Dokka-purple?logo=kotlin)](https://rallista.github.io/valhalla-mobile/)

This project builds [valhalla](https://github.com/valhalla/valhalla) as a static iOS or shared Android library.

It currently only exposes the route function for the primary purpose of generating turn by turn navigation routes
using a downloaded pre-parsed valhalla tileset.

We welcome contributions to expand the functionality of this library. See our [CONTRIBUTING.md](CONTRIBUTING.md)
for more information.
If you've got questions, would like to have informal discussions, or just want to ping us about a question, PR. Feel free 
to reach out on the OpenStreetMap Slack (osmus.slack.com) under the [#valhalla-mobile](`https://osmus.slack.com/archives/C08N6SUNZTJ`) channel.

## Setup

### Android

> Requires `minSdk` 26.

Add the engine plus the model artifacts. The models are needed to compile against
the `RouteRequest` / `ValhallaConfigBuilder` types — `valhalla-mobile` only pulls
them in at runtime, so they are not on the consumer's compile classpath by default.

Using a `libs.versions.toml` with a `build.gradle.kts`

```toml
[versions]
valhallaMobile = "0.5.1"
valhallaModels = "0.2.0"
osrm = "0.0.10"

[libraries]
valhalla-mobile = { group = "io.github.rallista", name = "valhalla-mobile", version.ref = "valhallaMobile" }
valhalla-models = { group = "io.github.rallista", name = "valhalla-models", version.ref = "valhallaModels" }
valhalla-models-config = { group = "io.github.rallista", name = "valhalla-models-config", version.ref = "valhallaModels" }
osrm-openapi = { group = "com.stadiamaps", name = "osrm-openapi", version.ref = "osrm" }
```

```kts
implementation(libs.valhalla.mobile)
implementation(libs.valhalla.models)
implementation(libs.valhalla.models.config)
implementation(libs.osrm.openapi) // for the OSRM branch of ValhallaResponse
```

Using a standard `build.gradle.kts`

```kts
implementation("io.github.rallista:valhalla-mobile:0.5.1")
implementation("io.github.rallista:valhalla-models:0.2.0")
implementation("io.github.rallista:valhalla-models-config:0.2.0")
implementation("com.stadiamaps:osrm-openapi:0.0.10")
```

Using a standard `build.gradle`

```
implementation 'io.github.rallista:valhalla-mobile:0.5.1'
implementation 'io.github.rallista:valhalla-models:0.2.0'
implementation 'io.github.rallista:valhalla-models-config:0.2.0'
implementation 'com.stadiamaps:osrm-openapi:0.0.10'
```

### iOS

In a swift package:

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/rallista/valhalla-mobile.git", from: "0.5.1"),
    ],
    targets: [
        .target(
            dependencies: [
                .product(name: "Valhalla", package: "valhalla-mobile")
            ]
        ),
    ]
)
```

## Usage

> Currently only `route` is exposed. `route()` blocks on the native engine — run it off the main thread.

### Android

```kotlin
// 1. Point Valhalla at a tile extract (.tar) — a bundled asset or a file you downloaded.
val tarFile = ValhallaFile.usingAsset(context, "valhalla_tiles.tar")
// val tarFile = ValhallaFile(context, "valhalla_tiles.tar") // context.filesDir/<name>

// 2. Build the config and the engine instance.
val config = ValhallaConfigBuilder()
    .withTileExtract(tarFile.absolutePath())
    .build()
val valhalla = Valhalla(context, config)

// 3. Request a route.
val request = RouteRequest(
    locations = listOf(
        RoutingWaypoint(lat = 42.5063, lon = 1.5218),
        RoutingWaypoint(lat = 42.5086, lon = 1.5394),
    ),
    costing = CostingModel.auto, // format defaults to RouteRequest.Format.json
)

// 4. Handle the response (sealed by format).
when (val response = valhalla.route(request)) {
    is ValhallaResponse.Json -> {
        val trip = response.jsonResponse.trip
        // trip.status, trip.summary, trip.legs[i].shape (encoded polyline, precision 1e6)
    }
    is ValhallaResponse.Osrm -> { /* only when format = RouteRequest.Format.osrm */ }
}
```

`route()` throws `ValhallaException` subclasses on failure — e.g.
`ValhallaException.Internal` (`ValhallaError(code=171, No suitable edges near location)`),
`InvalidResponse`, `InvalidError`, and `NotSupported` (`gpx` / `pbf`).

## Manually Building Valhalla C++

Fetching submodules

```sh
git submodule update --init --recursive
```

Set up VCPKG

```sh
git clone https://github.com/microsoft/vcpkg && git -C vcpkg checkout 2025.12.12
./vcpkg/bootstrap-vcpkg.sh
export VCPKG_ROOT=`pwd`/vcpkg
```

### iOS Swift Package

On iOS, you must pre-build the xcframework using the command:

```sh
./build.sh ios clean
```

### Android

**Prerequisites:** See [development.md](docs/development.md), specifically 
setting up NDK `29.0.14206865` to match CI.

The project's build.gradle.kts includes a build task that automatically runs the script below selectively per architecture.
It's also possible to run this manually:

```sh
./build.sh android clean
```

## Valhalla Fork

This project uses our fork of valhalla at <https://github.com/Rallista/valhalla> as a submodule. If a feature is missing, please
open an issue or PR on that repository to upgrade it to valhalla's latest version.

## References

- Valhalla <https://github.com/valhalla/valhalla>
- Swift Package Manager C++ (for fun - this repo takes the old approach) <https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html>
