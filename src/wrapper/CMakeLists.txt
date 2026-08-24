
project(valhalla-wrapper)

if(ANDROID_ABI)
    add_library(valhalla-wrapper SHARED)
    # Export only the JNI entry points. With everything else local, the linker's
    # --gc-sections can drop the code the wrapper never reaches.
    set_target_properties(valhalla-wrapper PROPERTIES
                          CXX_VISIBILITY_PRESET hidden
                          VISIBILITY_INLINES_HIDDEN ON)
    target_link_options(valhalla-wrapper PRIVATE -Wl,--exclude-libs,ALL)
else()
    add_library(valhalla-wrapper STATIC)
endif()

target_sources(valhalla-wrapper
               PUBLIC
               main.cpp valhalla_actor.cpp)

target_include_directories(valhalla-wrapper
                           PUBLIC
                           ${CMAKE_CURRENT_SOURCE_DIR}/include)