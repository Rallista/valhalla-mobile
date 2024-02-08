#!/bin/bash

mkdir -p protoc && cd protoc
export BUILD_DIR=`pwd`

echo "Building protobuf/protoc into $BUILD_DIR"

# Download and extract protobuf source code
PROTOBUF_VERSION=3.20.3
wget -nc https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-cpp-$PROTOBUF_VERSION.tar.gz
tar xvf protobuf-cpp-$PROTOBUF_VERSION.tar.gz
cd protobuf-$PROTOBUF_VERSION

# Build protobuf
./autogen.sh
./configure --prefix=$BUILD_DIR CFLAGS="-fPIC -DGOOGLE_PROTOBUF_NO_RTTI" CXXFLAGS="-fPIC -DGOOGLE_PROTOBUF_NO_RTTI"
make -j$(nproc)
make install

echo "Done building protobuf/protoc into $BUILD_DIR/protobuf-install"