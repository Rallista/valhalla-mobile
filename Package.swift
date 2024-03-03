// swift-tools-version:5.9
import PackageDescription

// Use the local binary if true
let useLocalBinary = Context.environment["VALHALLA_MOBILE_DEV"].flatMap(Bool.init) ?? false

// Use the local binary
var binaryTarget: Target = .binaryTarget(
    name: "ValhallaWrapper",
    path: "build/apple/valhalla-wrapper.xcframework"
)

// CI will replace the nils with the actual values when building a release
let binaryURL: String = "https://github.com/Rallista/valhalla-mobile/releases/tag/untagged-cac486a4dff1e116328a/"
let binaryChecksum: String = "e21720c6791297f9e030d8ab9cd5f261b42d696d0feb5960f6d23165e31346e7"

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
