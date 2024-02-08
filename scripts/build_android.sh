# Android SDK and NDK
export ANDROID_SDK=~/Library/Android/sdk
export NDK_DIR=$ANDROID_SDK/ndk/25.0.8775105  # <-- Update with the correct NDK path
# Android toolchain
export TOOLCHAIN_FILE=$NDK_DIR/build/cmake/android.toolchain.cmake

# TODO: Handle the abi and target as based on arguments
android_abis=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
android_targets=("aarch64-linux-android" "armv7a-linux-androideabi" "i686-linux-android" "x86_64-linux-android")

export ABI=$1
export TARGET=aarch64-linux-android
export ANDROID_PLATFORM=android-28

export PROTOBUF_LOCAL_DIR=`pwd`/protoc

export BUILD_DIR=`pwd`/build/android/$ABI/wrapper
export WRAPPER_DIR=`pwd`/src

mkdir -p $BUILD_DIR && cd $BUILD_DIR

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_TOOLS=OFF -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_NODE_BINDINGS=OFF -DENABLE_HTTP=OFF -DENABLE_SERVICES=OFF \
    -DENABLE_TESTS=OFF -DENABLE_BENCHMARKS=OFF \
    -DENABLE_STATIC_LIBRARY_MODULES=ON \
    -DProtobuf_PROTOC_EXECUTABLE=$PROTOBUF_LOCAL_DIR/bin/protoc \
    -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=$ANDROID_PLATFORM \
    -DANDROID_NDK=$NDK_DIR \
    -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
    -S $WRAPPER_DIR \
    -B .

make -j$(nproc)