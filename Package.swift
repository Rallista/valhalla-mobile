// swift-tools-version:5.8
import PackageDescription

// Use the local binary if true
let useLocalBinary = Context.environment["VALHALLA_MOBILE_DEV"].flatMap(Bool.init) ?? false

// Use the local binary
var binaryTarget: Target = .binaryTarget(
    name: "ValhallaWrapper",
    path: "build/apple/valhalla-wrapper.xcframework"
)

// CI will replace the nils with the actual values when building a release
let version: String = "0.6.1"
let binaryURL: String =
    "https://github.com/Rallista/valhalla-mobile/releases/download/\(version)/valhalla-wrapper.xcframework.zip"
let binaryChecksum: String = "c9698f4b77f885e78d814e1ee1aeb850ae2d78c55259193f362d16f7b7fa5003"

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
        .iOS("16.4")
        // .tvOS(.v13),
        // .watchOS(.v6),
        // .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "Valhalla",
            targets: ["Valhalla"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/Rallista/valhalla-openapi-models-swift.git",
            // 0.5.4 is the first release whose config models spell hierarchy_limits,
            // max_iterations, and allow_modification the way valhalla does. Before it,
            // every one of those keys was dropped from the config on the way through.
            .upToNextMinor(from: "0.5.4")),
        .package(
            url: "https://github.com/UInt2048/Light-Swift-Untar.git", .upToNextMajor(from: "1.0.4")),
        .package(url: "https://github.com/apple/swift-docc-plugin", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "Valhalla",
            dependencies: [
                "ValhallaObjc",
                "ValhallaWrapper",
                .product(name: "ValhallaConfigModels", package: "valhalla-openapi-models-swift"),
                .product(name: "ValhallaModels", package: "valhalla-openapi-models-swift"),
                .product(name: "Light-Swift-Untar", package: "Light-Swift-Untar"),
            ],
            path: "apple/Sources/Valhalla",
            resources: [
                .process("SupportData")
            ]
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
    cxxLanguageStandard: .cxx20
)
