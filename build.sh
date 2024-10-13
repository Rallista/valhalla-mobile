#!/bin/bash

# Fail on any error
set -e

ios_archs=("arm64-ios" "arm64-ios-simulator" "x64-ios-simulator")
android_archs=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")

build_ios() {
    local arch=$1
    if [ -z "$arch" ]; then
        echo "Building for all iOS architectures..."
        for arch in "${ios_archs[@]}"; do
            echo "Building for iOS architecture: $arch"
            ./scripts/build_apple.sh "$arch"
        done
    else
        echo "Building for iOS architecture: $arch"
        ./scripts/build_apple.sh "$arch"
    fi
}

build_android() {
    local arch=$1
    if [ -z "$arch" ]; then
        echo "Building for all Android architectures..."
        for arch in "${android_archs[@]}"; do
            echo "Building for Android architecture: $arch"
            ./scripts/build_android.sh "$arch"
        done
    else
        echo "Building for Android architecture: $arch"
        ./scripts/build_android.sh "$arch"
    fi
}

move_android_so() {
    local arch=$1
    if [ -z "$arch" ]; then
        echo "Moving .so files for all Android architectures..."
        for a in "${android_archs[@]}"; do
            ./scripts/move_android_so.sh "$a"
        done
    else
        echo "Moving .so files for Android architecture: $arch"
        ./scripts/move_android_so.sh "$arch"
    fi
}

if [ -d "$(pwd)/vcpkg" ]; then
  export VCPKG_ROOT="$(pwd)/vcpkg"
else
  # If VCPKG_ROOT is not set and vcpkg directory doesn't exist locally
  if [ -z "${VCPKG_ROOT+x}" ]; then
    echo "VCPKG_ROOT is not set and vcpkg directory not found in the current working directory."
    echo "Review setup in README.md or export a custom $VCPKG_ROOT."
    exit 1
  fi
fi

platform=""
arch=""
clean=false

while [[ $# -gt 0 ]]; do
    case $1 in
        ios|android|all)
            platform=$1
            ;;
        --ios)
            platform="ios"
            arch=$2
            shift
            ;;
        --android)
            platform="android"
            arch=$2
            shift
            ;;
        clean)
            clean=true
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# if the first argument is clean, then clean the build directory
if [ "$2" == "clean" ]; then
    if [ "$1" == "ios" ]; then
        echo "Cleaning the iOS build directory..."
        rm -rf build/apple
    elif [ "$1" == "android" ]; then
        echo "Cleaning the Android build directory..."
        rm -rf build/android
    else
        echo "Cleaning the build directory..."
        rm -rf build
    fi
fi

# Handle cleaning
if $clean_all; then
    echo "Cleaning all build directories..."
    rm -rf build
elif $clean; then
    if [ "$platform" == "ios" ]; then
        echo "Cleaning the iOS build directory..."
        rm -rf build/apple
    elif [ "$platform" == "android" ]; then
        echo "Cleaning the Android build directory..."
        rm -rf build/android
    else
        echo "Cleaning the build directory..."
        rm -rf build
    fi
fi

# Build based on platform
if [ "$platform" == "ios" ] || [ "$platform" == "all" ]; then
    build_ios "$arch"
    if [ -z "$arch" ]; then
        echo "Creating xcframework..."
        ./scripts/create_xcframework.sh
    fi
fi

if [ "$platform" == "android" ] || [ "$platform" == "all" ]; then
    build_android "$arch"
    move_android_so "$arch"
fi

echo "Done!"
