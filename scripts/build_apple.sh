#!/bin/bash

# Check for Xcode command line tools
if ! command -v xcodebuild &> /dev/null; then
    echo "Xcode command line tools not found. Please install Xcode."
    exit 1
fi

if [ -z ${VCPKG_ROOT+x} ]; then
  echo "Please set VCPKG_ROOT"
  exit 1
fi

# Set the path to the toolchains
vcpkg_toolchain_file=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
vcpkg_triplet_overlay=`pwd`/triplets

# Check if the first argument is a valid Apple architecture
if [ "$1" == "arm64-ios" ]; then
    sdk=iphoneos
    system_name=iOS
    min_deployment_target=16.4
    arch=arm64
    vcpkg_target_triplet=arm64-ios
elif [ "$1" == "arm64-ios-simulator" ]; then
    sdk=iphonesimulator
    system_name=iOS
    min_deployment_target=16.4
    arch=arm64
    vcpkg_target_triplet=arm64-ios-simulator
elif [ "$1" == "x64-ios-simulator" ]; then
    sdk=iphonesimulator
    system_name=iOS
    min_deployment_target=16.4
    arch=x86_64
    vcpkg_target_triplet=x64-ios-simulator
elif [ "$1" == "macos" ]; then
    sdk=macosx
    system_name=Darwin
    min_deployment_target=10.14
    arch=arm64 # TODO: Add x86_64 for older macs?
    vcpkg_target_triplet=arm64-osx # TODO: Try the normal one that's not in the community releases.
elif [ "$1" == "tvos" ]; then
    echo "Error tvos not supported yet." # error: 'fork' is unavailable: not available on watchOS, tvOS (& 'execvp')
    exit 1
    sdk=appletvos
    system_name=tvOS
    min_deployment_target=13.0
    arch=arm64
    vcpkg_target_triplet="" # TODO: Make a custom triplet?
elif [ "$1" == "watchos" ]; then
    echo "Error watchos not supported yet." # error: 'fork' is unavailable: not available on watchOS, tvOS (& 'execvp')
    exit 1
    sdk=watchos
    system_name=watchOS
    min_deployment_target=6.0
    arch=arm64
    vcpkg_target_triplet="" # TODO: Make a custom triplet?
elif [ "$1" == "visionos" ]; then
    echo "Error visionos not supported yet."
    exit 1
else
    echo "Error, first argument must be apple platform: iphoneos, iphonesimulator, macos, tvos, watchos, visionos"
    exit 1
fi

build_dir=`pwd`/build/apple/$vcpkg_target_triplet
wrapper_dir=`pwd`/src

# Move to the build directory
mkdir -p $build_dir && cd $build_dir

cmake -DCMAKE_TOOLCHAIN_FILE=$vcpkg_toolchain_file \
    -DVCPKG_TARGET_TRIPLET=$vcpkg_target_triplet \
    -DVCPKG_OVERLAY_TRIPLETS=$vcpkg_triplet_overlay \
    -DCMAKE_SYSTEM_NAME=$system_name \
    -DCMAKE_OSX_SYSROOT=$sdk \
    -DCMAKE_OSX_ARCHITECTURES=$arch \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$min_deployment_target \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -S $wrapper_dir \
    -B . \
    -G Xcode
cmake --build . --config Release --target install -- -jobs $(sysctl -n hw.ncpu)
