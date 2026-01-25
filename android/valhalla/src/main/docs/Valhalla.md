# Valhalla

Kotlin wrapper for the Valhalla routing engine.

## Overview

The `valhalla-mobile` library builds libvalhalla c++ for Android (and iOS). It provides a Kotlin 
interface to access the `ValhallaActor`. Currently, it only supports fetching routes but with 
additional Kotlin contributions, more features can be added.

## Getting Started

To use `Valhalla` in Kotlin, you'll need:

### The Offline Data - A Valhalla Tile Tar (or Folder)

To generate a route on a mobile device, you'll need a valhalla_tiles.tar file 
or a valhalla_tiles directory. The tile directory makes it easier to manage distinct offline regions. The tarball is more performant. Which one you use is a matter of convenience. (NOTE: you can mix disconnected tile regions together without any issues, but once you have possibly connected regions, you'll need to ensure they came from the same graph build or else the connections won't line up!)

They just need to be available to your app either through `assets` (useful for testing) 
or through internal/external storage for something synced from a backend.

Syncing real up to date valhalla tiles is one of the hard parts in using this repo. It's easy 
to get a pre-built tar, it's reasonable to bbox several tars and download them, but
dynamically syncing multiple tile regions built over various timeframes is where things
can get quite challenging.

Here are some useful resources:

- [Valhalla Tiles Doc](https://valhalla.github.io/valhalla/tiles/)
- [Bbox to Tiles Python Script/Example](https://valhalla.github.io/valhalla/tiles/#working-with-latitude-and-longitude-coordinates). I used this ages ago on my first POC server.
- Several of us are also working on [Valinor](https://github.com/stadiamaps/valinor/). Hope is
this may work quite well at dynamically slicing valhalla tile features. Think features like:
  - Mapbox's 5 mi/km radius of tile data around a full polyline route fetch from your API server.
  - Dynamically joining manually multiple bbox regions and allowing different download dates to work together.

There's a lot of opportunity to contribute here to a variety of projects to share the building 
blocks required to deliver this system.

## Usage

### Configuring Valhalla

> **Warning**: You can use valhalla with a static `valhalla.json` config file like most servers.
> However, you must prebuild it with the exact location of the tiles tarball or folder
> as your app would see it.

If your tiles are packaged in a `.tar` file:

```kotlin
// Code sample placeholder
```

In this example, we use `ValhallaConfig` to inject the path of the tarball we provided. 
You can see (and debug) this process in the test files.

If you're using a tile directory, the process is basically the same:

```kotlin
// Code sample placeholder
```

### Getting a route

Now that `valhalla` is initialized, you can use it to get a route.

```kotlin
// Code sample placeholder
```

### Working with Different Response Formats

Valhalla supports multiple response formats. The library handles both Valhalla JSON format 
and OSRM-compatible format:

```kotlin
// Code sample placeholder
```

## Android-Specific Considerations

### Context Requirements

The `Valhalla` class requires an Android `Context` to manage configuration files and access 
the device's filesystem. Make sure to pass an appropriate context (Application context is recommended 
for long-lived instances).

### Storage Permissions

Depending on where you store your tile data, you may need to request appropriate storage permissions. 
For Android 10 (API 29) and above, consider using scoped storage or the app-specific directory.

### File Management

The library uses `ValhallaConfigManager` to write configuration files to the device's internal storage. 
This ensures the native C++ library can access the configuration with an absolute file path.

## Architecture

The library consists of several key components:

- **Valhalla**: Main entry point for routing operations
- **ValhallaActor**: JNI bridge to the native C++ Valhalla library
- **ValhallaConfigManager**: Manages configuration file I/O
- **ValhallaResponse**: Sealed class for different response format types
- **ValhallaException**: Exception types for error handling

## Topics

### Core Classes

- `Valhalla`
- `ValhallaActor`
- `ValhallaResponse`

### Configuration

- `ValhallaConfigManager`
- `ValhallaConfig`

### File Management

- `ValhallaFile`
- `ValhallaFileAsset`

### Error Handling

- `ValhallaException`

## See Also

- [Valhalla API Models](https://github.com/Rallista/valhalla-mobile)
- [Valhalla Config Models](https://github.com/Rallista/valhalla-mobile)
- [OSRM API Models](https://github.com/Rallista/valhalla-mobile)