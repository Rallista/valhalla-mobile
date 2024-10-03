#!/bin/sh

# TODO: Remove
rm -rf build

# TODO: This triplet can be changed for all iOS, Android, etc builds.
# export ARCH=arm64-android
# export ARCH=x64-android

echo "set(VCPKG_BUILD_TYPE release)" >> vcpkg/triplets/$ARCH.cmake
export BUILD_DIR=`pwd`/build/android/$ARCH/wrapper
export WRAPPER_DIR=`pwd`/src
export TOOLCHAIN_FILE=`pwd`/vcpkg/scripts/buildsystems/vcpkg.cmake

# Move to the build directory
mkdir -p $BUILD_DIR && cd $BUILD_DIR

# vcpkg will install everything during cmake configuration
# if you want to ENABLE_SERVICES=ON, install https://github.com/kevinkreiser/prime_server#build-and-install (no Windows)
cmake -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
    -DENABLE_TOOLS=OFF -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_HTTP=OFF \
    -DENABLE_SERVICES=OFF -DENABLE_TESTS=OFF \
    -DENABLE_STATIC_LIBRARY_MODULES=ON \
    -S $WRAPPER_DIR \
    -B .
cmake --build . -- -j$(nproc)
