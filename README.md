# Valhalla Mobile

This project builds [valhalla](https://github.com/valhalla/valhalla) as a static iOS or shared Android library.

It currently only exposes the route function for the primary purpose of generating turn by turn navigation routes
using a downloaded pre-parsed valhalla tileset.

We welcome contributions to expand the functionality of this library. See our [CONTRIBUTING.md](CONTRIBUTING.md)
for more information.

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

The project's build.gradle.kts includes a build task that automatically runs the script below selectively per achitecture.
It's also possible to run this manually:

```sh
./build.sh android clean
```

## Valhalla Fork

This project uses our fork of valhalla at <https://github.com/Rallista/valhalla> as a submodule. If a feature is missing, please
open an issue or PR on that repository to upgrade it to valhalla's latest version.

## References

- Valhalla <https://github.com/valhalla/valhalla>
- Swift Package Manager C++ (for fun - this repo takes the old approach) <https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html>
