#!/bin/bash

# Check if the first argument is a valid Apple architecture
if [ "$1" == "iphoneos" ]; then
    export SDK="iphoneos"
    export SYSTEM_NAME="iOS"
    export OSX_DEPLOYMENT_TARGET="13.0"
    export OSX_ARCHITECTURE="arm64"
elif [ "$1" == "iphonesimulator" ]; then
    export SDK="iphonesimulator"
    export SYSTEM_NAME="iOS"
    export OSX_DEPLOYMENT_TARGET="13.0"
    export OSX_ARCHITECTURE="arm64"
elif [ "$1" == "iphonesimulator-legacy" ]; then
    export SDK="iphonesimulator"
    export SYSTEM_NAME="iOS"
    export OSX_DEPLOYMENT_TARGET="13.0"
    export OSX_ARCHITECTURE="x86_64"
elif [ "$1" == "macos" ]; then
    export SDK="macosx"
    export SYSTEM_NAME="Darwin"
    export OSX_DEPLOYMENT_TARGET="10.14"
    export OSX_ARCHITECTURE="arm64" # TODO: Add x86_64 for older macs?
elif [ "$1" == "tvos" ]; then
    echo "Error tvos not supported yet." # error: 'fork' is unavailable: not available on watchOS, tvOS (& 'execvp')
    exit 1
    export SDK="appletvos"
    export SYSTEM_NAME="tvOS"
    export OSX_DEPLOYMENT_TARGET="13.0"
    export OSX_ARCHITECTURE="arm64"
elif [ "$1" == "watchos" ]; then
    echo "Error watchos not supported yet." # error: 'fork' is unavailable: not available on watchOS, tvOS (& 'execvp')
    exit 1
    export SDK="watchos"
    export SYSTEM_NAME="watchOS"
    export OSX_DEPLOYMENT_TARGET="6.0"
    export OSX_ARCHITECTURE="arm64"
elif [ "$1" == "visionos" ]; then
    echo "Error visionos not supported yet."
    exit 1
else
    echo "Error, first argument must be apple platform: iphoneos, iphonesimulator, macos, tvos, watchos, visionos"
    exit 1
fi

# Protobuf built locally. This is simply to build headers with a matching protoc version on the local machine.
export PROTOBUF_LOCAL_DIR=`pwd`/protoc

# Check if protoc is available in the local directory
if [ ! -f $PROTOBUF_LOCAL_DIR/bin/protoc ]; then
    echo "Error: protoc not found in the local directory. Please run build_protoc_local.sh first."
    exit 1
fi

export BUILD_DIR=`pwd`/build/apple/$OSX_ARCHITECTURE/$SDK/wrapper
export WRAPPER_DIR=`pwd`/src

mkdir -p $BUILD_DIR && cd $BUILD_DIR

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SINGLE_FILES_WERROR=OFF -DENABLE_WERROR=OFF -DENABLE_TOOLS=OFF -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_SERVICES=OFF -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_NODE_BINDINGS=OFF -DENABLE_HTTP=OFF \
    -DENABLE_TESTS=OFF -DENABLE_BENCHMARKS=OFF \
    -DENABLE_STATIC_LIBRARY_MODULES=ON \
    -DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_LOCAL_DIR/bin/protoc \
    -DBoost_INCLUDE_DIR=/opt/homebrew/include \
    -DCMAKE_SYSTEM_NAME=$SYSTEM_NAME \
    -DCMAKE_OSX_SYSROOT=$SDK \
    -DCMAKE_OSX_ARCHITECTURES=$OSX_ARCHITECTURE \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -S $WRAPPER_DIR \
    -B . \
    -G Xcode

cmake --build $BUILD_DIR --config Release --target install -- -sdk $SDK