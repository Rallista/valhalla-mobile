# Set the minimum version of CMake that can be used
cmake_minimum_required(VERSION 3.14)

# Configure VCPKG
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake"
    CACHE STRING "Vcpkg toolchain file")

# Set the project name
project(valhalla-mobile)

# Valhalla requires at least C++20
set(CMAKE_CXX_STANDARD 20 CACHE STRING "C++ language version to use (default is 20)")
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Valhalla config for mobile.
set(ENABLE_TOOLS OFF)
set(ENABLE_DATA_TOOLS OFF)
set(ENABLE_PYTHON_BINDINGS OFF)
set(ENABLE_HTTP OFF)
set(ENABLE_SERVICES OFF)
set(ENABLE_TESTS OFF)
# TODO: Remove this once we fix the iOS errors w/ date library.
set(ENABLE_SINGLE_FILES_WERROR OFF)

# Set the output folder where your program will be created
set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)

# Disable deprecation
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-builtins")

# Configure OSX
if (APPLE)
    message(STATUS "Configured for APPLE")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -lpthread -Wno-shorten-64-to-32 -Wno-sign-compare")

    # tvOS and watchOS modifications
    if(CMAKE_OSX_SYSROOT MATCHES ".*watchos.*" OR CMAKE_OSX_SYSROOT MATCHES ".*appletvos.*")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DPOCO_NO_FORK_EXEC=1")
    endif()

    # Configure the date library
    set(BUILD_TZ_LIB ON CACHE INTERNAL "")
    set(MANUAL_TZ_DB ON CACHE INTERNAL "")
endif()

# WRAPPER ---------------------------------------------------------

add_subdirectory(wrapper)
target_include_directories(valhalla-wrapper PUBLIC wrapper/include)
install(DIRECTORY wrapper/include DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

# DEPENDENCIES ----------------------------------------------------

set(protobuf_BUILD_STATIC_LIBS ON CACHE INTERNAL "")

set(Protobuf_INCLUDE_DIR ${protobuf_SOURCE_DIR}/src)
set(Protobuf_LIBRARIES protobuf::libprotobuf-lite)

find_package(absl CONFIG REQUIRED)
find_package(Protobuf CONFIG REQUIRED)
find_package(Boost REQUIRED)
find_package(robin_hood CONFIG REQUIRED)
find_package(RapidJSON CONFIG REQUIRED)
find_package(unordered_dense CONFIG REQUIRED)

link_libraries(robin_hood::robin_hood)
include_directories(${ROBIN_HOOD_INCLUDE_DIRS})

link_libraries(rapidjson)
include_directories(${RAPIDJSON_INCLUDE_DIRS})

link_libraries(unordered_dense::unordered_dense)
include_directories(${UNORDERED_DENSE_INCLUDE_DIRS})

link_libraries(Boost::boost)
include_directories(${Boost_INCLUDE_DIRS})

add_subdirectory(valhalla/third_party/date date)

link_libraries(date)
include_directories(${Date_INCLUDE_DIRS})

add_subdirectory(valhalla)

# Valhalla source directory
set(VALHALLA_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/valhalla)
set_property(DIRECTORY valhalla PROPERTY VALHALLA_SOURCE_DIR ${VALHALLA_SOURCE_DIR})

target_link_libraries(valhalla-wrapper
    PRIVATE
    ${Protobuf_LIBRARIES}
    absl::base
    absl::log
    absl::strings
    absl::status
    Boost::boost
    valhalla
)

target_include_directories(valhalla-wrapper
    PRIVATE
    ${Boost_INCLUDE_DIRS}
    ${VALHALLA_SOURCE_DIR}
)

# Link installed headers ---------------------------------------------------------

function(install_vcpkg_libs_wildcard pattern)
    file(GLOB LIBS_TO_INSTALL
         "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}/lib/${pattern}.a")
    install(FILES ${LIBS_TO_INSTALL}
            DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
endfunction()

function(install_vcpkg_libs)
    foreach(lib ${ARGN})
        install(FILES
            "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}/lib/${lib}.a"
            DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
        )
    endforeach()
endfunction()

if (APPLE)
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/valhalla/third_party/date/include
            DESTINATION ${CMAKE_INSTALL_PREFIX})

    install(DIRECTORY ${Boost_INCLUDE_DIRS}
            DESTINATION ${CMAKE_INSTALL_PREFIX}
            COMPONENT development)

    install_vcpkg_libs(liblz4 libprotobuf-lite)
    install_vcpkg_libs_wildcard("libabsl*")
    install_vcpkg_libs_wildcard("libutf8*")
endif()

# Install the valhalla-wrapper library

install(TARGETS
        valhalla-wrapper
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
