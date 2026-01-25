Package com.valhalla.valhalla.files

A simple tool for the creation and management of valhalla file absolute paths. Typically,
this will be used with application directories like [`getExternalFilesDir()`](https://developer.android.com/reference/android/content/Context#getExternalFilesDir(java.lang.String)). There are several dir locations depending on your use case: [Android Docs - Context](https://developer.android.com/reference/android/content/Context#ACTIVITY_SERVICE).

```kt
val tilesDir = appContext.getExternalFilesDir()
val tarFile = ValhallaFile(appContext, "valhalla_tiles.tar", tilesDir!!)
```

Typically, you'd want to sync a tar or tiles directory to the specific directory on the device
configured as `ValhallaFile`.

Alternatively, this class includes `usingAsset` for asset bundled files. This can be used to 
load smaller tiles sets that are bundled with your APK. Assets are also used for testing 
in this library.
