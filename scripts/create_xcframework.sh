#/bin/sh

# Handle Simulator

if [ ! -d "build/apple/arm64-x86_64/iphonesimulator" ]; then
    mkdir -p build/apple/arm64-x86_64/iphonesimulator/wrapper/Release-iphonesimulator
fi

# Merge the two simulator libraries into one fat library
lipo -create build/apple/arm64/iphonesimulator/libvalhalla_all.a build/apple/x86_64/iphonesimulator/libvalhalla_all.a \
    -output build/apple/arm64-x86_64/iphonesimulator/libvalhalla_all.a

xcodebuild -create-xcframework \
    -library build/apple/arm64/iphoneos/libvalhalla_all.a -headers build/apple/arm64/iphoneos/wrapper/install/include \
    -library build/apple/arm64-x86_64/iphonesimulator/libvalhalla_all.a -headers build/apple/arm64/iphoneos/wrapper/install/include \
    -output build/apple/valhalla-wrapper.xcframework
