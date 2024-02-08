# Set the minimum version of CMake that can be used
cmake_minimum_required(VERSION 3.14)

# Set the project name
project(valhalla_mobile)

# Valhalla requires at least C++17
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ language version to use (default is 17)")
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set the output folder where your program will be created
set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)

# Disable package config for statics.
# TODO: Delete this
# set(WITH_PKGCONFIG OFF)

# Configure OSX
if (APPLE)
    message(STATUS "Configured for APPLE")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-shorten-64-to-32 -Wno-deprecated-builtins")
    # TODO: Delete if not needed
    # set(CMAKE_XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.valhalla.libvalhalla_wrapper")
    # set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "")
endif()

# Create the project library

# WRAPPER ---------------------------------------------------------

add_subdirectory(wrapper)
target_include_directories(valhalla_wrapper PUBLIC wrapper/include)
install(DIRECTORY wrapper/include DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

# PROTOBUF ---------------------------------------------------------

message(STATUS "Protobuf fetching from github...")

# Fetch Protobuf source code
# https://cmake.org/cmake/help/latest/module/FetchContent.html#overriding-where-to-find-cmakelists-txt
include(FetchContent)
FetchContent_Declare(
    protobuf
    GIT_REPOSITORY https://github.com/protocolbuffers/protobuf.git
    GIT_TAG v3.20.3  # You can specify a particular commit or tag
    SOURCE_SUBDIR cmake
    FIND_PACKAGE_ARGS NAMES protobuf
)

message(STATUS "Protobuf fetching - done")
message(STATUS "Protobuf building...")

set(WITHPROTOC {$Protobuf_PROTOC_EXECUTABLE} CACHE INTERNAL "")
set(protobuf_BUILD_STATIC_LIBS ON CACHE INTERNAL "")
set(protobuf_BUILD_LIBPROTOC ON CACHE INTERNAL "")
set(protobuf_BUILD_PROTOC_BINARIES OFF CACHE INTERNAL "")
set(protobuf_BUILD_TESTS OFF CACHE INTERNAL "")
set(protobuf_BUILD_CONFORMANCE OFF CACHE INTERNAL "")
set(protobuf_BUILD_EXAMPLES OFF CACHE INTERNAL "")

FetchContent_MakeAvailable(Protobuf)

message(STATUS "Protobuf bulding -done")

set(Protobuf_INCLUDE_DIR ${protobuf_SOURCE_DIR}/src)
set(Protobuf_LIBRARIES protobuf::libprotobuf-lite)

include(FindProtobuf) 
find_package(Protobuf CONFIG REQUIRED)

if (NOT Protobuf_FOUND)
    message(FATAL_ERROR "Protobuf not found")
endif()

# Link Protobuf
target_link_libraries(valhalla_wrapper PRIVATE protobuf::libprotobuf)

# VALHALLA ---------------------------------------------------------

add_subdirectory(valhalla)
target_link_libraries(valhalla_wrapper PRIVATE valhalla)
target_include_directories(valhalla_wrapper PRIVATE valhalla/valhalla)
install(DIRECTORY valhalla/valhalla DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

# Valhalla proto files
# TODO: Filter out subdirectories (they're empty but still there).
set(VALHALLA_PROTO_HEADERS_DIR ${CMAKE_BINARY_DIR}/valhalla/src/valhalla/proto)
install(DIRECTORY ${VALHALLA_PROTO_HEADERS_DIR}/
        DESTINATION ${CMAKE_INSTALL_PREFIX}/include/valhalla/proto
        FILES_MATCHING PATTERN "*.h")

# BOOST ---------------------------------------------------------

message(STATUS "Boost_INCLUDE_DIR: ${Boost_INCLUDE_DIR}")

# Find all header files in Boost_INCLUDE_DIR/boost
file(GLOB_RECURSE BOOST_HEADERS ${Boost_INCLUDE_DIR}/boost/*.hpp ${Boost_INCLUDE_DIR}/boost/*.h)

# Process each header file to determine its relative path
foreach(BOOST_HEADER ${BOOST_HEADERS})
    # Get the relative path of the header file relative to Boost_INCLUDE_DIR/boost
    file(RELATIVE_PATH BOOST_HEADER_RELATIVE ${Boost_INCLUDE_DIR}/boost ${BOOST_HEADER})
    
    # Extract the directory part of the relative path
    get_filename_component(BOOST_HEADER_DIR ${BOOST_HEADER_RELATIVE} DIRECTORY)
    
    # Install the header file to the destination directory within the installation directory
    install(FILES ${BOOST_HEADER} DESTINATION ${CMAKE_INSTALL_PREFIX}/include/boost/${BOOST_HEADER_DIR})
endforeach()

# Date (valhalla/third_party) ---------------------------------------------------------

install(DIRECTORY valhalla/third_party/date/include DESTINATION ${CMAKE_INSTALL_PREFIX})

# Install the valhalla_wrapper library

install(TARGETS 
    valhalla
    valhalla-loki
    valhalla-thor
    valhalla-odin
    valhalla-proto
    valhalla-tyr
    valhalla_wrapper 
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
