
project(valhalla_wrapper)

if(ANDROID_ABI)
    add_library(valhalla_wrapper SHARED)
else()
    add_library(valhalla_wrapper STATIC)
endif()

target_sources(valhalla_wrapper
               PUBLIC
               main.cpp valhalla_actor.cpp)

target_include_directories(valhalla_wrapper
                           PUBLIC
                           ${CMAKE_CURRENT_SOURCE_DIR}/include)