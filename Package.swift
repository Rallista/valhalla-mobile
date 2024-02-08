// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "ValhallaMobile",
    platforms: [
        .iOS(.v13)
        // TODO: Add support for other platforms?
    ],
    products: [
        .library(
            name: "Valhalla",
            targets: ["Valhalla"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "Valhalla",
            dependencies: ["ValhallaObjc", "ValhallaWrapper"],
            path: "apple/Sources/Valhalla"
        ),
        .target(
            name: "ValhallaObjc",
            dependencies: ["ValhallaWrapper"],
            path: "apple/Sources/ValhallaObjc"
        ),
        .binaryTarget(
            name: "ValhallaWrapper",
            path: "build/valhalla_wrapper.xcframework"
        ),
        .testTarget(
            name: "ValhallaTests",
            dependencies: ["Valhalla"],
            path: "apple/Tests"
        )
    ],
    cLanguageStandard: .gnu17,
    cxxLanguageStandard: .cxx17
)
