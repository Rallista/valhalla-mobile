# Valhalla Mobile

[![Valhalla](https://img.shields.io/badge/Valhalla-3.6.3-blue)](https://github.com/valhalla/valhalla/releases/tag/3.6.3)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRallista%2Fvalhalla-mobile%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Rallista/valhalla-mobile)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRallista%2Fvalhalla-mobile%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Rallista/valhalla-mobile)
[![Maven Central](https://img.shields.io/maven-central/v/io.github.rallista/valhalla-mobile)](https://central.sonatype.com/artifact/io.github.rallista/valhalla-mobile)
[![Kotlin Docs](https://img.shields.io/badge/Kotlin%20Dokka-purple?logo=kotlin)](https://rallista.github.io/valhalla-mobile/)

This project builds [valhalla](https://github.com/valhalla/valhalla) as a static iOS or shared Android library.

It currently exposes valhalla's `route` action, for the primary purpose of generating turn by turn navigation
routes using a downloaded pre-parsed valhalla tileset, along with the two map matching actions — `trace_route`,
which snaps a GPS trace to the road network and returns a route along it, and `trace_attributes`, which returns
the attributes of every edge the trace matched — and `height`, which samples elevations under a shape. All of
them run entirely against the tiles on the device.

## Supported actions

| Feature | Valhalla action | Android | iOS |
| --- | --- | :-: | :-: |
| Routing | `route` | [✅][kt-route] | [✅][ios-route] |
| Map matching | `trace_route` | [✅][kt-trace-route] | [✅][ios-trace-route] |
| | `trace_attributes` | [✅][kt-trace-attributes] | [✅][ios-trace-attributes] |
| Elevation | `height` | [✅][kt-height] | [✅][ios-height] |
| Time-distance matrix | `sources_to_targets` | – | – |
| Optimized route | `optimized_route` | – | – |
| Isochrones | `isochrone` | – | – |
| Nearest edge or node | `locate` | – | – |
| Graph expansion | `expansion` | – | – |

Responses are valhalla's own JSON on both platforms, decoded into generated model types.
`route` can also answer in the OSRM format, decoded on Android and returned as raw JSON on iOS.
GPX is reachable through the raw request methods, which every action has on both platforms.
PBF is not supported; requesting it returns an error.
`height` needs a directory of elevation tiles in the config; without them every height is null.

## Documentation

### Android (Kotlin)

[API reference (Dokka)](https://rallista.github.io/valhalla-mobile/)

- [Fetching a route, response formats, and errors](https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla/index.html)
- [Managing tile files on the device](https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla.files/index.html)
- [Building a valhalla config](https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla.config/index.html)

### iOS (Swift)

[API reference (DocC)](https://swiftpackageindex.com/Rallista/valhalla-mobile/documentation/valhalla): installation, offline tiles, configuration, and fetching a route.

### This repository

- [docs/development.md](docs/development.md): local toolchain setup, including the NDK version CI uses.
- [docs/src/architecture.md](docs/src/architecture.md): how the C++, JNI, and Obj-C++ layers fit together.
- [docs/src/bumping-valhalla.md](docs/src/bumping-valhalla.md): upgrading the valhalla submodule.

We welcome contributions to expand the functionality of this library. See our [CONTRIBUTING.md](CONTRIBUTING.md)
for more information.
If you've got questions, would like to have informal discussions, or just want to ping us about a question, PR. Feel free 
to reach out on the OpenStreetMap Slack (osmus.slack.com) under the [#valhalla-mobile](`https://osmus.slack.com/archives/C08N6SUNZTJ`) channel.

## Setup

### Android

You need the engine plus the model packages; the models define the request and config types your
code compiles against.

Using a `libs.versions.toml` with a `build.gradle.kts`

```toml
[versions]
valhallaMobile = "0.6.1"
valhallaModels = "0.5.2"
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
implementation(libs.osrm.openapi) // Only needed for the OSRM branch of ValhallaResponse.
```

Using a standard `build.gradle.kts`

```kts
implementation("io.github.rallista:valhalla-mobile:0.6.1")
implementation("io.github.rallista:valhalla-models:0.5.2")
implementation("io.github.rallista:valhalla-models-config:0.5.2")
implementation("com.stadiamaps:osrm-openapi:0.0.10")
```

Using a standard `build.gradle`

```
implementation 'io.github.rallista:valhalla-mobile:0.6.1'
implementation 'io.github.rallista:valhalla-models:0.5.2'
implementation 'io.github.rallista:valhalla-models-config:0.5.2'
implementation 'com.stadiamaps:osrm-openapi:0.0.10'
```

### iOS

In a swift package:

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/rallista/valhalla-mobile.git", from: "0.6.1"),
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

[kt-route]: https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla/-valhalla/route.html
[kt-trace-route]: https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla/-valhalla/trace-route.html
[kt-trace-attributes]: https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla/-valhalla/trace-attributes.html
[kt-height]: https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla/-valhalla/height.html
[ios-route]: <https://swiftpackageindex.com/Rallista/valhalla-mobile/documentation/valhalla/valhalla/route(request:)>
[ios-trace-route]: <https://swiftpackageindex.com/Rallista/valhalla-mobile/documentation/valhalla/valhalla/traceroute(request:)>
[ios-trace-attributes]: <https://swiftpackageindex.com/Rallista/valhalla-mobile/documentation/valhalla/valhalla/traceattributes(request:)>
[ios-height]: <https://swiftpackageindex.com/Rallista/valhalla-mobile/documentation/valhalla/valhalla/height(request:)>
