#/bin/sh

# Fail on any error
set -e

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

if [ "$2" == "clean-all" ]; then
    echo "Cleaning all, all builds and protoc directory..."
    rm -rf build
    rm -rf protoc
fi

if [ ! -d "protoc" ]; then
    echo "Building protoc for your local machine into the ./protoc directory..."
    mkdir protoc
    ./scripts/build_protoc_local.sh
else
    echo "Protoc already exists in the ./protoc directory. If you want to rebuild it, delete the directory and run this script again."
fi

if [ "$1" == "ios" ] || [ "$1" == "all" ]; then
    echo "Building iOS..."
    ./scripts/build_apple.sh iphoneos
    ./scripts/build_apple.sh iphonesimulator

    echo "Creating xcframework..."
    ./scripts/create_xcframework.sh
fi

if [ "$1" == "android" ] || [ "$1" == "all" ]; then
    echo "Building Android..."
    ./scripts/build_android.sh arm64-v8a
    ./scripts/build_android.sh armeabi-v7a
    ./scripts/build_android.sh x86_64
    ./scripts/build_android.sh x86

    echo "Moving Android .so files to the correct directory..."
    ./scripts/move_android_so.sh
fi

echo "Done!"
