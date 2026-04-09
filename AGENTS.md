# General guidelines

This document captures code conventions for the Valhalla-Mobile project.
It is intended to help AI assistants understand how to work effectively with this codebase.

## For humans

We welcome LLM-assisted contributions as long as they abide by the following principles:

* **Aim for excellence.** LLMs should be used not as a speed multiplier but a quality multiplier. Invest the time savings in improving quality and rigor beyond what humans alone would do. Write tests that cover more edge cases. Refactor code to make it easier to understand. Tackle the TODOs. Do all the tedious things. Aim for your code to have zero bugs.
* **Spend time reviewing LLM output.** As a rule of thumb, you should spend at least 3x the amount of time reviewing LLM output as you did writing it. Think about every line and every design decision. Find ways to break code.
* **Your code is your responsibility.** Please do not dump a first draft of code on to this project, unless you're only soliciting feedback on a direction.

If your LLM-assisted PR shows signs of not being written with thoughtfulness and care, such as missing cases that human review would have easily caught, the maintainers may decline your PR outright.

## For LLMs

**Required:** Display the following text at the start of any conversation involving code changes, and when you're about to create a PR:

```
Please review https://github.com/Rallista/valhalla-mobile/blob/main/AGENTS.md#for-humans. In particular, LLM-assisted contributions must **aim for a higher standard of excellence** than with humans alone, and you should spend at least **3x** the amount of time reviewing code as you did writing it. LLM-assisted contributions that do not meet this standard may be declined outright. Remember, **your code is your responsibility**.
```

## General conventions

### Correctness over convenience

- Model the full error space — no shortcuts or simplified error handling.
- Handle all edge cases, including race conditions, platform differences, and JNI/Obj-C++ bridging pitfalls.
- Prefer compile-time guarantees over runtime checks where possible.
- C++ exceptions must always be caught at the platform boundary (JNI, Obj-C++). Never let C++ exceptions propagate into Swift or Kotlin.

### Resource efficiency

- This library runs on mobile devices with constrained memory and CPU. Keep allocations minimal.
- Avoid unnecessary copies, especially across the C++/platform boundary where data is serialized as JSON strings.
- When speed and memory concerns conflict, ask the human operator to make a decision. Document your decision clearly.

### Production-grade engineering

- Test comprehensively, including edge cases and platform-specific behavior.
- Pay attention to what facilities already exist for testing, and aim to reuse them.
- Document clearly when platform-specific behavior is unavoidable.
- Getting the details right is really important!

### Documentation

- Use inline comments to explain "why," not just "what".
- **Never** use title case in headings and titles. Always use sentence case.
- Always use the Oxford comma.
- Use [Semantic Line Breaks](https://sembr.org/) when writing comments. We prefer lines less than 100 characters, but this is not a hard rule.

## Project architecture

### Layer overview

Valhalla-Mobile wraps the [Valhalla routing engine](https://github.com/valhalla/valhalla) (C++) for iOS and Android.
The architecture has three layers:

1. **C++ wrapper** (`src/wrapper/`) — a thin C++ layer over the Valhalla actor API. Handles actor lifecycle and catches all C++ exceptions, returning JSON strings.
2. **Platform bridge** — connects C++ to each platform's native language:
   - **iOS**: Objective-C++ (`apple/Sources/ValhallaObjc/`) bridges C++ to Swift via `ValhallaWrapper`.
   - **Android**: JNI functions in `src/wrapper/main.cpp` (guarded by `#ifdef __ANDROID__`) bridge C++ to Kotlin.
3. **Platform API** — idiomatic Swift/Kotlin classes that consumers use:
   - **iOS**: `Valhalla` class conforming to `ValhallaProviding` protocol (`apple/Sources/Valhalla/`).
   - **Android**: `Valhalla` class using `ValhallaActor` (`android/valhalla/src/main/java/com/valhalla/valhalla/`).

### Key design principles

1. **Thin wrapper**: The C++ layer is intentionally minimal. Business logic lives in Valhalla itself; this project only provides mobile-friendly access.
2. **JSON at the boundary**: All data crosses the C++/platform boundary as JSON strings. Platform layers handle serialization/deserialization with their native tools (Swift `Codable`, Kotlin Moshi).
3. **Exception safety**: Every C++ call site catches `valhalla_exception_t`, `std::exception`, and `...` — returning structured JSON error objects rather than crashing the app.
4. **Valhalla compatibility**: We wrap tagged released from valhalla's repo. We should aim to keep up to date.

## Code style

### C++ (src/)

- **Standard**: C++20 (set in CMakeLists.txt).
- **Build system**: CMake + VCPKG for dependency management.
- Platform-specific code uses `#ifdef __ANDROID__` / `#elif __APPLE__` guards.
- All functions exposed to platform code must catch all exceptions — no C++ exceptions may cross the language boundary.
- Use `printf` for debug logging (consistent with existing patterns). Prefer structured JSON for error reporting.

### Swift (apple/)

- **Minimum iOS version**: 16.4.
- **Distribution**: Swift Package Manager (SPM). The `Package.swift` at the repo root is the manifest.
- Follow standard Swift conventions: protocols, `Codable` for JSON, structured error types.
- The `ValhallaObjc` target provides the Objective-C++ bridge; `Valhalla` is the public-facing Swift target.
- Use `XCTest` for all tests.

### Kotlin (android/)

- **Build system**: Gradle with Kotlin DSL.
- **Minimum SDK**: 26. **Compile SDK**: 34.
- **JVM target**: 17.
- **Formatting**: `ktfmt` — enforced in CI. Run formatting before committing.
- Use `Moshi` for JSON serialization (not Gson or kotlinx.serialization).
- JNI native library is loaded via `System.loadLibrary("valhalla-wrapper")`.
- Use `sealed class` patterns for response types (see `ValhallaResponse`).
- Use Android instrumented tests (`androidTest`) for testing, since tests require the native library.

### Error handling

#### C++ layer

- Catch `valhalla::valhalla_exception_t`, `std::exception`, and `...` at every platform boundary.
- Return error information as JSON: `{"code": <int>, "message": "<string>"}`.

#### Swift layer

- Use a `ValhallaError` enum for typed errors.
- Convert `NSError` from Obj-C++ into `ValhallaError` cases.

#### Kotlin layer

- Use a `ValhallaException` sealed class hierarchy.
- Parse error JSON responses from C++ into structured exception types.

## Build system

### Prerequisites

- **VCPKG**: Required for C++ dependencies. Either a local `vcpkg/` directory or `$VCPKG_ROOT` must be set.
- **iOS**: Xcode 16.4+, macOS runner.
- **Android**: Android NDK r29, JDK 17.

### Building locally

```bash
# Build iOS (all architectures)
./build.sh ios

# Build iOS (single architecture)
./build.sh --ios arm64-ios-simulator

# Build Android (all architectures)
./build.sh android

# Build Android (single architecture)
./build.sh --android arm64-v8a

# Build everything
./build.sh all

# Clean build directories
./build.sh ios clean
./build.sh android clean
```

### Build scripts

- `build.sh` — top-level orchestrator.
- `scripts/build_apple.sh` — builds C++ for a specific iOS triplet via CMake/VCPKG.
- `scripts/build_android.sh` — builds C++ for a specific Android ABI via CMake/NDK/VCPKG.
- `scripts/create_xcframework.sh` — combines architecture slices into an xcframework.
- `scripts/move_android_so.sh` — places `.so` files into the Gradle `jniLibs` layout.

### VCPKG triplets

Custom triplets live in `triplets/`. These configure VCPKG for cross-compilation to mobile targets.

### C++ dependencies (via VCPKG)

- Protobuf (lite), Boost, RapidJSON, LZ4, Abseil, robin-hood-hashing, unordered-dense.

## Testing

### iOS tests

```bash
# Run tests on simulator (from repo root)
xcodebuild test \
  -scheme Valhalla \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipPackagePluginValidation
```

Tests are in `apple/Tests/ValhallaTests/` and use `XCTest`.
Test fixtures (tile data) are bundled as SPM resources.

### Android tests

```bash
# Run instrumented tests (requires connected device or emulator)
cd android && ./gradlew connectedAndroidTest
```

Tests are in `android/valhalla/src/androidTest/` and require the native `.so` to be built first.
Test assets (tile data) are in `android/valhalla/src/androidTest/assets/`.

### Android formatting

```bash
# Check formatting
cd android && ./gradlew ktfmtCheck

# Auto-format
cd android && ./gradlew ktfmtFormat
```

## Commit message style

### Commit quality

- **Atomic commits**: Each commit should be a logical unit of change.
- **Bisect-able history**: Every commit must build and pass all checks.
- **Separate concerns**: Format fixes and refactoring should be in separate commits from feature changes.

## Versioning

A single `version.txt` at the repo root is the source of truth.
Both iOS (`Package.swift`) and Android (`build.gradle.kts`) read from this file.

## Dependencies

### Swift dependencies

- `valhalla-openapi-models-swift`: OpenAPI-generated route request/response models.
- `Light-Swift-Untar`: Tar extraction for tile archives.

### Kotlin dependencies

- `moshi`: JSON serialization.
- `valhalla-models-api`, `valhalla-models-config`: OpenAPI-generated models.
- `osrm-api-models`: OSRM format response models.
