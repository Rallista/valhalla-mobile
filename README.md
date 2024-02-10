# Valhalla Mobile

This project builds [valhalla](https://github.com/valhalla/valhalla) as a static iOS or shared Android library. It currently only exposes the route function for the primary purpose of generating turn by turn navigation routes using a downloaded pre-parsed valhalla tileset.

> This library is in early POC. Feel free to write up issues if you're insterested in contributing.

## Usage

TBA

## Local Build

### iOS Swift Package

```sh
git submodule update --init --recursive

./build.sh ios clean
```

### Android

TBA

## References

- Valhalla <https://github.com/valhalla/valhalla>
- Swift Package Manager C++ <https://www.swift.org/documentation/articles/wrapping-c-cpp-library-in-swift.html>
