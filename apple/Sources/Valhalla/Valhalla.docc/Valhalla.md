# ``Valhalla``

Swift wrapper for the Valhalla routing engine.

## Overview

The `valhalla-mobile` library builds libvalhalla c++ for iOS (and Android). It provides a Swift 
interface to access the `ValhallaActor`. Currently, it only supports fetching routes through the 
but with additional swift contributions, more features can be added.

## Getting Started

To use `Valhalla` in swift, you'll need:

### The Offline Data - A Valhalla Tile Tar (or Folder)

To generate a route on a mobile device, you'll need a valhalla_tiles.tar file 
or a valhalla_tiles directory. The tile directory makes it easier to manage distinct offline regions. The tarball is more performant. Which one you use is a matter of convenience. (NOTE: you can mix disconnected tile regions together without any issues, but once you have possibly connected regions, you'll need to ensure they came from the same graph build or else the connections won't line up!)
They just need to be available to your app either through a `Bundle.` file (useful for testing) 
or through `FileManager` for something synced from a backend.

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

> Warning: You can use valhalla with a static `valhalla.json` config file like most servers.
> However, you must prebuild it with the exact location of the tiles tarball or folder
> as your app would see it. 

If your tiles are packaged in a `.tar` file:

```swift
import Valhalla
import ValhallaConfigModels

// You can replace this with FileManager for server downloaded data.
// The key note is, you need `.url(forResource:,withExtension:)`. 
// Valhalla's C++ uses the absolute file path to load the config and tar
let tilesTarUrl = Bundle.module.url(forResource: "TestData/valhalla_tiles", withExtension: "tar")!
let config = try ValhallaConfig(tileExtractTar: tilesTarUrl)
let valhalla = try Valhalla(config)
```

In this example, we use `ValhallaConfig` to inject the path of the tarball we provided. 
You can see (and debug) this process in [`TestValhallaWithTar.swift`](apple/Tests/ValhallaTests/TestValhallaWithTar.swift).

If you're using a tile directory. The process is basically same: 

```swift
import Valhalla
import ValhallaConfigModels

// You can replace this with FileManager for server downloaded data.
// The key note is, you need the directory path URL. 
// Valhalla's C++ uses the absolute file path to load the config and tar
let tilesDirectoryURL = Bundle.module.resourceURL!.appendingPathComponent("TestData/valhalla_tiles", isDirectory: true)!
let config = try ValhallaConfig(tilesDir: tilesDirectoryURL)
let valhalla = try Valhalla(config)
```

### Getting a route

Now that `let valhalla` is initialized, you can use it to get a route.

```swift
import Valhalla
import ValhallaModels

let request = RouteRequest(
    locations: [
        RoutingWaypoint(lat: 38.429719, lon: -108.827425),
        RoutingWaypoint(lat: 38.4604331, lon: -108.8817009)
    ],
    costing: .auto,
    directionsOptions: DirectionsOptions(units: .mi)
)

do {
    let response = try valhalla.route(request: request)
    print("Route found: \(response.trip.statusMessage ?? "")")
} catch {
    print("Error calculating route: \(error)")
}
``` 

## Topics

### Essentials

- ``Valhalla``
