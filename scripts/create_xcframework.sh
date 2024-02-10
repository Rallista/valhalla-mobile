#/bin/sh

# build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-mjolnir.a \
libtool -static -o build/apple/arm64/iphoneos/libvalhalla_all.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libprotobuf-lite.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libtz.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-baldr.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-loki.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-meili.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-midgard.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-odin.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-proto.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-sif.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-skadi.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-thor.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-tyr.a \
    build/apple/arm64/iphoneos/wrapper/install/lib/libvalhalla-wrapper.a

# build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-mjolnir.a \
libtool -static -o build/apple/arm64/iphonesimulator/libvalhalla_all.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libprotobuf-lite.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libtz.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-baldr.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-loki.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-meili.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-midgard.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-odin.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-proto.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-sif.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-skadi.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-thor.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-tyr.a \
    build/apple/arm64/iphonesimulator/wrapper/install/lib/libvalhalla-wrapper.a

xcodebuild -create-xcframework \
    -library build/apple/arm64/iphoneos/libvalhalla_all.a -headers build/apple/arm64/iphoneos/wrapper/install/include \
    -library build/apple/arm64/iphonesimulator/libvalhalla_all.a -headers build/apple/arm64/iphoneos/wrapper/install/include \
    -output build/apple/valhalla-wrapper.xcframework
