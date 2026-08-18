# Valhalla Mobile

[![Valhalla](https://img.shields.io/badge/Valhalla-3.6.3-blue)](https://github.com/valhalla/valhalla/releases/tag/3.6.3)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRallista%2Fvalhalla-mobile%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Rallista/valhalla-mobile)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRallista%2Fvalhalla-mobile%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Rallista/valhalla-mobile)
[![Maven Central](https://img.shields.io/maven-central/v/io.github.rallista/valhalla-mobile)](https://central.sonatype.com/artifact/io.github.rallista/valhalla-mobile)
[![Kotlin Docs](https://img.shields.io/badge/Kotlin%20Dokka-purple?logo=kotlin)](https://rallista.github.io/valhalla-mobile/)

This project builds [valhalla](https://github.com/valhalla/valhalla) as a static iOS or shared Android library.

It currently only exposes the route function for the primary purpose of generating turn by turn navigation routes
using a downloaded pre-parsed valhalla tileset.

## Supported features

Core valhalla covers considerably more ground than this library exposes.
The table below is the current surface, per platform:

| Feature | Valhalla action | Android | iOS |
| --- | --- | :-: | :-: |
| Routing | `route` | ✅ | ✅ |
| Map matching | `trace_route`, `trace_attributes` | – | – |
| Time-distance matrix | `sources_to_targets` | – | – |
| Optimized route | `optimized_route` | – | – |
| Isochrones | `isochrone` | – | – |
| Elevation | `height` | – | – |
| Nearest edge or node | `locate` | – | – |
| Graph expansion | `expansion` | – | – |

Routes come back in valhalla's own JSON format on both platforms.
Android additionally decodes the [OSRM](https://github.com/stadiamaps/osrm-openapi-kotlin) format;
on iOS, non-default formats are available as raw JSON through `route(rawRequest:)`.
`gpx` and `pbf` are not supported anywhere yet.

Widening this table is exactly the kind of contribution we're looking for.
See [CONTRIBUTING.md](CONTRIBUTING.md) for how to get started.

## Documentation

Installation and usage live alongside the API reference for each platform:

### Android (Kotlin)

[API reference (Dokka)](https://rallista.github.io/valhalla-mobile/)

- [Requirements, installation, and getting started](https://rallista.github.io/valhalla-mobile/)
- [Managing tile files on the device](https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla.files/index.html)
- [Building a valhalla config](https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla.config/index.html)
- [Fetching a route, response formats, and errors](https://rallista.github.io/valhalla-mobile/-valhalla%20-mobile/com.valhalla.valhalla/index.html)

### iOS (Swift)

[API reference (DocC)](https://swiftpackageindex.com/Rallista/valhalla-mobile/documentation/valhalla)

- Installation, sourcing offline tiles, configuring valhalla, and fetching a route are all covered
  on that page. The catalog source is [Valhalla.docc](apple/Sources/Valhalla/Valhalla.docc).

### This repository

- [CONTRIBUTING.md](CONTRIBUTING.md) — how to contribute.
- [docs/development.md](docs/development.md) — local toolchain setup, including the NDK version CI uses.
- [docs/src/architecture.md](docs/src/architecture.md) — how the C++, JNI, and Obj-C++ layers fit together.
- [docs/src/bumping-valhalla.md](docs/src/bumping-valhalla.md) — upgrading the valhalla submodule.

If you've got questions, would like to have informal discussions, or just want to ping us about a question, PR. Feel free 
to reach out on the OpenStreetMap Slack (osmus.slack.com) under the [#valhalla-mobile](`https://osmus.slack.com/archives/C08N6SUNZTJ`) channel.

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
