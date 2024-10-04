#!/bin/zsh

# TODO: Remove
rm -rf build

export VCPKG_ROOT=`pwd`/vcpkg

# Check for Xcode command line tools
if ! command -v xcodebuild &> /dev/null; then
    echo "Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Set the path to the toolchains
vcpkg_toolchain_file=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
vcpkg_triplet_overlay=$VCPKG_ROOT/triplets/community

# Define the platforms and architectures
declare -A platforms=(
    ["iOS"]="OS64"
    ["iOS_Simulator"]="SIMULATOR64"
    ["watchOS"]="WATCHOS"
    ["watchOS_Simulator"]="SIMULATOR_WATCHOS"
    ["tvOS"]="TVOS"
    ["tvOS_Simulator"]="SIMULATOR_TVOS"
)

platform="iphoneos"
sdk="iphoneos"
arch="arm64"

vcpkg_target_triplet=arm64-ios

build_dir=`pwd`/build/apple/$sdk/wrapper
wrapper_dir=`pwd`/src

# Move to the build directory
mkdir -p $build_dir && cd $build_dir

# vcpkg will install everything during cmake configuration
# -DENABLE_BITCODE=OFF \
# -DENABLE_ARC=ON \
# -DENABLE_VISIBILITY=ON \
# -DENABLE_STRICT_TRY_COMPILE=ON \
cmake -DCMAKE_TOOLCHAIN_FILE=$vcpkg_toolchain_file \
    -DVCPKG_TARGET_TRIPLET=$vcpkg_target_triplet \
    -DVCPKG_OVERLAY_TRIPLETS=$vcpkg_triplet_overlay \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=$sdk \
    -DCMAKE_OSX_ARCHITECTURES=$arch \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -DENABLE_TOOLS=OFF -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_HTTP=OFF \
    -DENABLE_SERVICES=OFF -DENABLE_TESTS=OFF \
    -S $wrapper_dir \
    -B . \
    -G Xcode
cmake --build . --config Release -- -jobs $(sysctl -n hw.ncpu)
