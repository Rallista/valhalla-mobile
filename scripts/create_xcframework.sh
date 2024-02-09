#/bin/sh

# build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-mjolnir.a \
libtool -static -o build/ios/arm64/iphoneos/libvalhalla_all.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libprotobuf-lite.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libtz.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-baldr.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-loki.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-meili.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-midgard.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-odin.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-proto.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-sif.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-skadi.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-thor.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla-tyr.a \
    build/ios/arm64/iphoneos/wrapper/install/lib/libvalhalla_wrapper.a

# build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-mjolnir.a \
libtool -static -o build/ios/arm64/iphonesimulator/libvalhalla_all.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libprotobuf-lite.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libtz.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-baldr.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-loki.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-meili.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-midgard.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-odin.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-proto.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-sif.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-skadi.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-thor.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-tyr.a \
    build/ios/arm64/iphonesimulator/wrapper/install/lib/libvalhalla_wrapper.a

xcodebuild -create-xcframework \
    -library build/ios/arm64/iphoneos/libvalhalla_all.a -headers build/ios/arm64/iphoneos/wrapper/install/include \
    -library build/ios/arm64/iphonesimulator/libvalhalla_all.a -headers build/ios/arm64/iphoneos/wrapper/install/include \
    -output build/valhalla_wrapper.xcframework
