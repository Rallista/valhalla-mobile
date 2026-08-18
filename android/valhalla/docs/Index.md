# Module Valhalla Mobile

The `valhalla-mobile` library builds libvalhalla c++ for Android (and iOS). It provides a Kotlin 
interface to access the `ValhallaActor`. Currently, it only supports fetching routes but with 
additional Kotlin contributions, more features can be added.

## Requirements

`valhalla-mobile` requires `minSdk` 26.

## Installation

Add the engine plus the model artifacts.
The models are needed to compile against the `RouteRequest` and `ValhallaConfigBuilder` types —
`valhalla-mobile` only pulls them in at runtime,
so they are not on the consumer's compile classpath by default.

Using a version catalog (`libs.versions.toml`) with a `build.gradle.kts`:

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
implementation(libs.osrm.openapi) // Only needed for the OSRM branch of ValhallaResponse.
```

Using a standard `build.gradle.kts`:

```kts
implementation("io.github.rallista:valhalla-mobile:0.5.1")
implementation("io.github.rallista:valhalla-models:0.2.0")
implementation("io.github.rallista:valhalla-models-config:0.2.0")
implementation("com.stadiamaps:osrm-openapi:0.0.10")
```

Using a standard `build.gradle`:

```
implementation 'io.github.rallista:valhalla-mobile:0.5.1'
implementation 'io.github.rallista:valhalla-models:0.2.0'
implementation 'io.github.rallista:valhalla-models-config:0.2.0'
implementation 'com.stadiamaps:osrm-openapi:0.0.10'
```

## Getting started

Using the library takes three steps, one per package:

1. Point Valhalla at a tile extract or tile directory with `com.valhalla.valhalla.files`.
2. Build a config for that path with `com.valhalla.valhalla.config`.
3. Create a `com.valhalla.valhalla.Valhalla` instance and request a route.

Each package page below carries the snippets for its step,
and `com.valhalla.valhalla` shows the three composed end to end.

#### See Also

- [Valhalla OpenAPI Models Kotlin](https://github.com/Rallista/valhalla-openapi-models-kotlin)
- [OSRM OpenAPI Models Kotlin (and iOS)](https://github.com/stadiamaps/osrm-openapi-kotlin)
