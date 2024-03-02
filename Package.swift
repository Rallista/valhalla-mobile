// swift-tools-version:5.9
import PackageDescription

// Use the local binary if true
let useLocalBinary = true

// Use the local binary
var binaryTarget: Target = .binaryTarget(
    name: "ValhallaWrapper",
    path: "build/apple/valhalla-wrapper.xcframework"
)

// CI will replace the nils with the actual values when building a release
let binaryURL: String = "https://uploads.github.com/repos/Rallista/valhalla-mobile/releases/144484538/assets?name/valhalla-wrapper.xcframework.zip"
let binaryChecksum: String = "f97c2c3d2b0721a40b934e714edb942e3a1be4746b1363a90205346f37514352"

if !useLocalBinary {
    binaryTarget = .binaryTarget(
        name: "ValhallaWrapper",
        url: binaryURL,
        checksum: binaryChecksum
    )
}

let package = Package(
    name: "ValhallaMobile",
    platforms: [
        .iOS(.v13),
        // .tvOS(.v13),
        // .watchOS(.v6),
        // .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "Valhalla",
            targets: ["Valhalla"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.1")),
        .package(url: "https://github.com/UInt2048/Light-Swift-Untar.git", from: "1.0.4"),
    ],
    targets: [
        .target(
            name: "ValhallaModels",
            dependencies: ["AnyCodable"],
            path: "apple/Sources/Generated"
        ),
        .target(
            name: "Valhalla",
            dependencies: [
                "ValhallaObjc",
                "ValhallaWrapper",
                "ValhallaModels",
                .product(name: "Light-Swift-Untar", package: "Light-Swift-Untar"),
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
        binaryTarget,
        .testTarget(
            name: "ValhallaTests",
            dependencies: ["Valhalla"],
            path: "apple/Tests/ValhallaTests",
            resources: [.copy("TestData")]
        ),
    ],
    cLanguageStandard: .gnu17,
    cxxLanguageStandard: .cxx17
)
