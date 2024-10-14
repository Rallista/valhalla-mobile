#!/bin/bash

move_arch() {
    local arch=$1
    local src_dir="build/android/$arch/wrapper/wrapper"
    local dest_dir="android/valhalla/src/main/jniLibs/$arch"

    mkdir -p "$dest_dir"
    if [ -f "$src_dir/libvalhalla-wrapper.so" ]; then
        mv "$src_dir/libvalhalla-wrapper.so" "$dest_dir/"
        echo "Moved $arch libvalhalla-wrapper.so"
    else
        echo "Warning: $arch libvalhalla-wrapper.so not found"
    fi
}

# The architectures that exist for android and can be moved.
architectures=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")

# Check if an architecture is provided as an argument
if [ $# -eq 1 ]; then
    # Check if the provided architecture is valid
    if [[ " ${architectures[@]} " =~ " $1 " ]]; then
        move_arch "$1"
    else
        echo "Error: Invalid architecture. Supported architectures are: ${architectures[*]}"
        exit 1
    fi
else
    # If no argument is provided, move all architectures
    for arch in "${architectures[@]}"; do
        move_arch "$arch"
    done
fi
