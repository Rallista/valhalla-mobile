// swift-tools-version:5.9
import PackageDescription

// Use the local binary if true
let useLocalBinary = true

// Use the local binary
var binaryTarget: Target = .binaryTarget(
    name: "ValhallaWrapper",
    path: "build/apple/valhalla-wrapper.xcframework")

// CI will replace the nils with the actual values when building a release
let binaryURL: String = "https://github.com/Rallista/valhalla-mobile/releases/download//valhalla-wrapper.xcframework.zip"
let binaryChecksum: String = "778cad95640cf911e686d754cc5127936923d3382e46210a063e9fa5e19e6265"

if !useLocalBinary {
    binaryTarget = .binaryTarget(
        name: "ValhallaWrapper",
        url: binaryURL,
        checksum: binaryChecksum)
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
        binaryTarget,
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
