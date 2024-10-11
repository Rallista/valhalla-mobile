#/bin/sh

# build/apple/arm64/iphoneos/wrapper/install/lib/libprotobuf-lite.a \
# build/apple/arm64/iphoneos/install/lib/libtz.a \
libtool -static -o build/apple/arm64-ios/libvalhalla_all.a \
    build/apple/arm64-ios/install/lib/libvalhalla.a \
    build/apple/arm64-ios/install/lib/libvalhalla-wrapper.a

# build/apple/arm64/iphonesimulator/wrapper/install/lib/libprotobuf-lite.a \
# build/apple/arm64/iphonesimulator/install/lib/libtz.a \
libtool -static -o build/apple/arm64-ios-simulator/libvalhalla_all.a \
    build/apple/arm64-ios-simulator/install/lib/libvalhalla.a \
    build/apple/arm64-ios-simulator/install/lib/libvalhalla-wrapper.a

# build/apple/x86_64/iphonesimulator/wrapper/install/lib/libprotobuf-lite.a \
# build/apple/x86_64/iphonesimulator/install/lib/libtz.a \
libtool -static -o build/apple/x64-ios-simulator/libvalhalla_all.a \
    build/apple/x64-ios-simulator/install/lib/libvalhalla.a \
    build/apple/x64-ios-simulator/install/lib/libvalhalla-wrapper.a

if [ ! -d "build/apple/arm64-x64-ios-simulator" ]; then
    mkdir -p build/apple/arm64-x64-ios-simulator
fi

# Merge the two simulator libraries into one fat library
lipo -create build/apple/arm64-ios-simulator/libvalhalla_all.a build/apple/x64-ios-simulator/libvalhalla_all.a \
    -output build/apple/arm64-x64-ios-simulator/libvalhalla_all.a

xcodebuild -create-xcframework \
    -library build/apple/arm64-ios/libvalhalla_all.a -headers build/apple/arm64-ios/install/include \
    -library build/apple/arm64-x64-ios-simulator/libvalhalla_all.a -headers build/apple/arm64-ios/install/include \
    -output build/apple/valhalla-wrapper.xcframework
