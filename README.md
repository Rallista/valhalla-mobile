# Valhalla Mobile

This project builds [valhalla](https://github.com/valhalla/valhalla) as a static iOS or shared Android library. It currently only exposes the route function for the primary purpose of generating turn by turn navigation routes using a downloaded pre-parsed valhalla tileset.

> This library is in early POC. Feel free to write up issues if you're insterested in contributing.

## Setup

### Android

Using a `libs.versions.toml` with a `build.gradle.kts`

```toml
[verisons]
valhallaMobile = "0.1.0"
[libraries]
valhalla-mobile = { group = "io.github.rallista", name = "valhalla-mobile", version.ref = "valhallaMobile" }
```

```kts
implementation(libs.valhalla.mobile)
```

Using a standard `build.gradle.kts`

```kts
implementation("io.github.rallista:valhalla-mobile:0.1.0")
```

Using a standard `build.gradle`

```
implementation 'io.github.rallista:valhalla-mobile:0.1.0'
```

### iOS

In a swift package:

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/rallista/valhalla-mobile.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            dependencies: [
                .product(name: "Valhalla", package: "valhalla-mobile")
            ]
        ),
    ]
)
```

## Manually Building Valhalla C++

Set up VCPKG

```sh
git clone https://github.com/microsoft/vcpkg && git -C vcpkg checkout 2024.09.23
./vcpkg/bootstrap-vcpkg.sh
export VCPKG_ROOT=`pwd`/vcpkg
```

### iOS Swift Package

On iOS, you must pre-build the xcframework using the command:

```sh
./build.sh ios clean
```

### Android

The project's build.gradle.kts includes a build task that runs the script below.
It's also possible to run this manually and copy the lib.so files automatically using:

```sh
./build.sh android clean
```

## Upgrading Valhalla

When a new valhalla release comes out at <https://github.com/valhalla/valhalla/releases>.

TODO: Make this a script once it's proven.

```sh
# Clean up valhalla submodule (important this is not concurrent.)
git submodule deinit -f --all
git submodule update --init

# Checkout the latest release branch
cd src/valhalla
git checkout {version-tag} # E.g. `git checkout 3.5.0`

# Install recursive submodules now that the exact version of valhalla is selected.
git submodule update --init --recursive

# Return to this repo's root directory
cd ../../
```

At this point valhalla's src folder has been updated and prepared. Now it's time to test if the existing `src/CMakeLists.txt` still builds by running
an iOS and Android build.

## References

- Valhalla <https://github.com/valhalla/valhalla>
- Swift Package Manager C++ <https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html>
