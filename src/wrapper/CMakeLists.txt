
project(valhalla-wrapper)

if(ANDROID_ABI)
    add_library(valhalla-wrapper SHARED)
else()
    add_library(valhalla-wrapper STATIC)
endif()

target_sources(valhalla-wrapper
               PUBLIC
               main.cpp valhalla_actor.cpp)

target_include_directories(valhalla-wrapper
                           PUBLIC
                           ${CMAKE_CURRENT_SOURCE_DIR}/include)