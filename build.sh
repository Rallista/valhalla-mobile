#/bin/sh

# if the first argument is clean, then clean the build directory
if [ "$1" == "clean" ]; then
    echo "Cleaning the build directory"
    rm -rf build
fi

if [ "$1" == "clean-all" ]; then
    echo "Cleaning the build and protoc directory"
    rm -rf build
    rm -rf protoc
fi

if [ ! -d "protoc" ]; then
    echo "Building protoc for your local machine into the ./protoc directory"
    mkdir protoc
    ./scripts/build_protoc_local.sh
else
    echo "Protoc already exists in the ./protoc directory. If you want to rebuild it, delete the directory and run this script again."
fi

# TODO: add support for tvOS, watchOS, visionOS, and macOS?
echo "Building iOS"
./scripts/build_ios.sh iphoneos
./scripts/build_ios.sh iphonesimulator

# x86_64 is not supported with the current build system. It fails with the following error:
#   /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.2.sdk/usr/include/machine/endian.h:37:2: error: architecture not supported
#   #error architecture not supported
# TODO: Enable x86_64 support if you're configuring an older xcode/ios version
# ./scripts/build_ios.sh x86_64

# echo "Building Android"
# ./scripts/build_android.sh arm64-v8a
# ./scripts/build_android.sh armeabi-v7a
# ./scripts/build_android.sh x86_64
# ./scripts/build_android.sh x86

echo "Done with all build scripts"

echo "Creating xcframework"
./scripts/create_xcframework.sh