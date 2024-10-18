#!/bin/bash

#
# 1. Check the presence of required environment variables
#
if [ -z ${ANDROID_NDK_HOME+x} ]; then
  echo "Please set ANDROID_NDK_HOME"
  exit 1
fi

if [ -z ${VCPKG_ROOT+x} ]; then
  echo "Please set VCPKG_ROOT"
  exit 1
fi

#
# 2. Set the path to the toolchains
#
vcpkg_toolchain_file=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
android_toolchain_file=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake
vcpkg_triplet_overlay=`pwd`/triplets

# Check if the first argument is a valid Apple architecture
if [ "$1" == "arm64-v8a" ]; then
    android_abi=arm64-v8a
    vcpkg_target_triplet=arm64-android
elif [ "$1" == "armeabi-v7a" ]; then
    android_abi=armeabi-v7a
    vcpkg_target_triplet=arm-android
elif [ "$1" == "x86_64" ]; then
    android_abi=x86_64
    vcpkg_target_triplet=x64-android
elif [ "$1" == "x86" ]; then
    android_abi=x86
    vcpkg_target_triplet=x86-android
else
    echo "Error, first argument must be an android architecture: arm, arm64, x64, or x86. Found ${1}"
    exit 1
fi

export BUILD_DIR=`pwd`/build/android/$android_abi/wrapper
wrapper_dir=`pwd`/src

# Move to the build directory
mkdir -p $BUILD_DIR && cd $BUILD_DIR

# vcpkg will install everything during cmake configuration
cmake -DCMAKE_TOOLCHAIN_FILE=$vcpkg_toolchain_file \
    -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=$android_toolchain_file \
    -DVCPKG_OVERLAY_TRIPLETS=$vcpkg_triplet_overlay \
    -DVCPKG_TARGET_TRIPLET=$vcpkg_target_triplet \
    -DANDROID_ABI=$android_abi \
    -S $wrapper_dir \
    -B .
cmake --build . --config Release -- -j$(nproc)
