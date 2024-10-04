#!/bin/zsh

# TODO: Remove
rm -rf build

export VCPKG_ROOT=`pwd`/vcpkg

#
# 1. Check the presence of required environment variables
#
if [ -z ${ANDROID_NDK_HOME+x} ]; then
  echo "Please set ANDROID_NDK_HOME"
  exit 1
fi
# if [ -z ${VCPKG_ROOT+x} ]; then
#   echo "Please set VCPKG_ROOT"
#   exit 1
# fi

#
# 2. Set the path to the toolchains
#
vcpkg_toolchain_file=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
android_toolchain_file=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake

#
# 3. Select a pair "Android abi" / "vcpkg triplet"
# Uncomment one of the four possibilities below
#

# android_abi=armeabi-v7a
# vcpkg_target_triplet=arm-android

# android_abi=x86
# vcpkg_target_triplet=x86-android

android_abi=arm64-v8a
vcpkg_target_triplet=arm64-android

# android_abi=x86_64
# vcpkg_target_triplet=x64-android

export BUILD_DIR=`pwd`/build/android/$android_abi/wrapper
wrapper_dir=`pwd`/src

# Move to the build directory
mkdir -p $BUILD_DIR && cd $BUILD_DIR

# vcpkg will install everything during cmake configuration
cmake -DCMAKE_TOOLCHAIN_FILE=$vcpkg_toolchain_file \
    -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=$android_toolchain_file \
    -DVCPKG_TARGET_TRIPLET=$vcpkg_target_triplet \
    -DANDROID_ABI=$android_abi \
    -DENABLE_TOOLS=OFF -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_HTTP=OFF \
    -DENABLE_SERVICES=OFF -DENABLE_TESTS=OFF \
    -S $wrapper_dir \
    -B .
cmake --build . -- -j$(nproc)
