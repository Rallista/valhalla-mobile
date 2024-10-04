# Set the minimum version of CMake that can be used
cmake_minimum_required(VERSION 3.14)

# Configure VCPKG
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake"
    CACHE STRING "Vcpkg toolchain file")

# Set the project name
project(valhalla-mobile)

# Valhalla requires at least C++17
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ language version to use (default is 17)")
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set the output folder where your program will be created
set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)

# Disable deprecation
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-builtins")

# Configure OSX
if (APPLE)
    message(STATUS "Configured for APPLE")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-shorten-64-to-32 -Wno-sign-compare")

    # tvOS and watchOS modifications
    if(CMAKE_OSX_SYSROOT MATCHES ".*watchos.*" OR CMAKE_OSX_SYSROOT MATCHES ".*appletvos.*")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DPOCO_NO_FORK_EXEC=1")
    endif()
endif()

# WRAPPER ---------------------------------------------------------

add_subdirectory(wrapper)
target_include_directories(valhalla-wrapper PUBLIC wrapper/include)
install(DIRECTORY wrapper/include DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

# DEPENDENCIES ----------------------------------------------------

# Find packages using vcpkg
find_package(Protobuf CONFIG REQUIRED)
find_package(Boost REQUIRED)
find_package(date CONFIG REQUIRED)
find_package(robin_hood CONFIG REQUIRED)
find_package(RapidJSON CONFIG REQUIRED)

# Start Global
link_libraries(robin_hood::robin_hood)
include_directories(${ROBIN_HOOD_INCLUDE_DIRS})

link_libraries(rapidjson)
include_directories(${RAPIDJSON_INCLUDE_DIRS})

link_libraries(Boost::boost)
include_directories(${Boost_INCLUDE_DIRS})
# End Global

add_subdirectory(valhalla)
# Valhalla source directory
set(VALHALLA_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/valhalla)
set_property(DIRECTORY valhalla PROPERTY VALHALLA_SOURCE_DIR ${VALHALLA_SOURCE_DIR})

target_link_libraries(valhalla-wrapper
    PRIVATE
    protobuf::libprotobuf
    Boost::boost
    date::date
    valhalla
)
target_include_directories(valhalla-wrapper
    PRIVATE
    ${Boost_INCLUDE_DIRS}
    ${VALHALLA_SOURCE_DIR}
)

# Date (valhalla/third_party) ---------------------------------------------------------

if (APPLE)
    # Configure the date library
    set(BUILD_TZ_LIB ON CACHE INTERNAL "")
    set(MANUAL_TZ_DB ON CACHE INTERNAL "")

    add_subdirectory(valhalla/third_party/date date)
    target_link_libraries(valhalla-wrapper PRIVATE date)
    target_include_directories(valhalla-wrapper PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/date/include)
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/valhalla/third_party/date/include DESTINATION ${CMAKE_INSTALL_PREFIX})
endif()

# Install the valhalla-wrapper library

install(TARGETS
    valhalla
    valhalla-baldr
    valhalla-loki
    valhalla-meili
    valhalla-midgard
    valhalla-odin
    valhalla-sif
    valhalla-skadi
    valhalla-thor
    valhalla-tyr
    valhalla-proto
    valhalla-wrapper
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
