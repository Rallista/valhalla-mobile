# Architecture Overview

This library is a wrapper around the libvalhalla C++ library and provides mobile friendly
interfaces for both iOS and Android. To accomplish this with modern Swift and Kotlin (and potentially more),
we use the following architecture:

## iOS

TODO: We want to simplify our current architecture w/ https://github.com/Rallista/valhalla-mobile/issues/42

## Android

```plaintext
+---------------------------+
|         `android`         |
|     (Kotlin API Layer)    |
+---------------------------+
              ^
              |
              v
+---------------------------+
|       `src/wrapper`       |
|     (JNI Wrapper Layer)   |
+---------------------------+
              ^
              |
              v
+---------------------------+
|       `src/valhalla`      |
|   (C++ libvalhalla core)  |
+---------------------------+
```

## Layer Overviews

### Valhalla C++ Core [`src/valhalla`](src/valhalla)

This is the third party valhalla C++ library's source code. It's maintained in this fork
<https://github.com/Rallista/valhalla> and is included as a submodule in this repository.

### C++ Wrapper [`src/wrapper`](src/wrapper)

The wrapper contains simplified C++ functions that wrap valhalla features, only accepting
and returning primitive types. This layer is responsible for taking parameters from the Swift,
Kotlin, or other language APIs, executing a valhalla function, and returning the result.

Actions do not run on the thread that calls in. Each one is handed to a dedicated thread
with a 16 MB stack and joined before the call returns, because valhalla's map matcher recurses
once per matched edge and a long trace overflows the ~1 MB stack a mobile worker thread has
([#89](https://github.com/Rallista/valhalla-mobile/issues/89)). Calls stay synchronous, and the
JNI and Obj-C++ code above keeps running on the platform's own thread, so no JNI attach is
involved. See [`valhalla_actor.cpp`](src/wrapper/valhalla_actor.cpp).

For Android, this layer requires JNI. See [`main.cpp`](src/wrapper/main.cpp#L14). JNI is tricky,
but there are many resources available:

- [Android - JNI Tips](https://developer.android.com/training/articles/perf-jni)
- Other Libraries - e.g. [maplibre-native](https://github.com/maplibre/maplibre-native)
- AI assitants - they can help quickly learn and iterate various JNI patterns that may be applicable.
