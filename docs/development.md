# Setting Up for Development

## Prerequisites

- **To Build for Android** [Android Studio](https://developer.android.com/studio)
- **To Build for Apple** [Xcode](https://developer.apple.com/xcode/) requires macOS.

## On macOS

All of these instructions are assuming macOS.

```sh
brew install cmake
brew install pkg-config
```

### Android NDK

Ensure you have added `ANDROID_NDK_HOME` to your path.
CI is currently using `29.0.14206865`, which would look like something like this
(assuming macOS):

```sh
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/29.0.14206865/
```
