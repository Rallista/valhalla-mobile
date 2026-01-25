Package com.valhalla.valhalla.config

Manage a valhalla configuration json file (`valhalla.json`). This is similar to operating valhalla on a 
server, but we generate the file from code to correctly specify paths relative to the app's 
filesystem.

The following code snippet demonstrates how to create a `ValhallaConfig` using `ValhallaFile` for
absolute paths. In this case we've chosen `getExternalFilesDir()` for the path, a suitable location for 
storing app-specific files. There are several dir locations depending on your use case: [Android Docs - Context](https://developer.android.com/reference/android/content/Context#ACTIVITY_SERVICE).

```kt
val tilesDir = appContext.getExternalFilesDir()
val tarFile = ValhallaFile(appContext, "valhalla_tiles.tar", tilesDir!!)

// This is the config object we'll pass to the Valhalla class.
val config = ValhallaConfigBuilder().withTileExtract(tarFile.absolutePath()).build()
```
