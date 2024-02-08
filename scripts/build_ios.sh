#!/bin/bash

export SYSTEM_NAME="iOS" # "tvOS" "watchOS" "visionOS"

# Check if the first argument is a valid iOS architecture
if [ "$1" != "iphonesimulator" ] && [ "$1" != "iphoneos" ]; then
    echo "Error, first argument must be apple architecture (e.g.) iphoneos and iphonesimulator."
    exit 1
fi

# Set the iOS architecture based on the first argument
export SDK=$1
export OSX_ARCHITECTURE="arm64"
export MIN_IOS_VERSION="13.0"

# Protobuf built locally.
export PROTOBUF_LOCAL_DIR=`pwd`/protoc

# Check if protoc is available in the local directory
if [ ! -f $PROTOBUF_LOCAL_DIR/bin/protoc ]; then
    echo "Error: protoc not found in the local directory. Please run build_protoc_local.sh first."
    exit 1
fi

export BUILD_DIR=`pwd`/build/ios/$OSX_ARCHITECTURE/$SDK/wrapper
export WRAPPER_DIR=`pwd`/src

mkdir -p $BUILD_DIR && cd $BUILD_DIR

# -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
# -DCMAKE_INSTALL_PREFIX=`pwd`/_install \
# -DCMAKE_IOS_INSTALL_COMBINED=YES \
# -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
# -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SINGLE_FILES_WERROR=OFF -DENABLE_WERROR=OFF -DENABLE_TOOLS=OFF -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_SERVICES=OFF -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_NODE_BINDINGS=OFF -DENABLE_HTTP=OFF \
    -DENABLE_TESTS=OFF -DENABLE_BENCHMARKS=OFF \
    -DENABLE_STATIC_LIBRARY_MODULES=ON \
    -DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_LOCAL_DIR/bin/protoc \
    -DBoost_INCLUDE_DIR=/opt/homebrew/include \
    -DCMAKE_SYSTEM_NAME=$SYSTEM_NAME \
    -DCMAKE_OSX_ARCHITECTURES=$OSX_ARCHITECTURE \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$MIN_IOS_VERSION \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -S $WRAPPER_DIR \
    -B . \
    -G Xcode

cmake --build $BUILD_DIR --config Release --target install -- -sdk $SDK