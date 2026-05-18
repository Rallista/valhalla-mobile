
project(valhalla-wrapper)

if(ANDROID_ABI)
    add_library(valhalla-wrapper SHARED)
else()
    add_library(valhalla-wrapper STATIC)
endif()

target_sources(valhalla-wrapper
               PUBLIC
               main.cpp valhalla_actor.cpp)

# Android-only JNI bridge that lets Kotlin supply an HTTP client used by
# Valhalla's GraphReader to fetch tiles via `mjolnir.tile_url`.
if(ANDROID_ABI)
    target_sources(valhalla-wrapper PUBLIC jni_http_client.cpp)
endif()

target_include_directories(valhalla-wrapper
                           PUBLIC
                           ${CMAKE_CURRENT_SOURCE_DIR}/include)