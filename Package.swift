// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ValhallaMobile",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "Valhalla",
            targets: ["Valhalla"])
    ],
    dependencies: [
        .package(url: "https://github.com/UInt2048/Light-Swift-Untar.git", from: "1.0.4")
    ],
    targets: [
        .target(
            name: "Valhalla",
            dependencies: [
                "ValhallaObjc",
                "ValhallaWrapper",
                .product(name: "Light-Swift-Untar", package: "Light-Swift-Untar")
            ],
            path: "apple/Sources/Valhalla",
            resources: [.copy("SupportData")]
        ),
        .target(
            name: "ValhallaObjc",
            dependencies: ["ValhallaWrapper"],
            path: "apple/Sources/ValhallaObjc",
            linkerSettings: [.linkedLibrary("z")]
        ),
        .binaryTarget(
            name: "ValhallaWrapper",
            path: "build/apple/valhalla-wrapper.xcframework"
        ),
        .testTarget(
            name: "ValhallaTests",
            dependencies: ["Valhalla"],
            path: "apple/Tests/ValhallaTests",
            resources: [.copy("TestData")]
        )
    ],
    cLanguageStandard: .gnu17,
    cxxLanguageStandard: .cxx17
)
