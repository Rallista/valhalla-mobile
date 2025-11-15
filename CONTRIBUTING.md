# Contributing

We're stoked that you're interested in working on valhalla-mobile!
This contribution guide will get you started developing in no time,
as well as provide some guidelines to follow when submitting an issue or PR.

## Best Practices for Contributions

We welcome contributions from community!
Due to the size and complexity of the code, below are some best practices that ensure smooth collaboration.

It is a good idea to discuss large proposed changes before proceeding to an issue ticket or PR.
The project team is active in the following forums:

* For larger discussions where it would be desirable to have wider input / a less ephemeral record,
  consider starting a thread on [GitHub Discussions](https://github.com/Rallista/valhalla-mobile/discussions).
  This makes it easier to find and reference the discussion in the future.

### Testing

Both new features and bugfixes should update or add unit test cases where possible
to prevent regressions and demonstrate correctness.

New tools for testing are always welcome to simplify the complexity of the testing codebase.

### New Features

For new features, you should generally start by opening a new issue.
That will allow for separate tracking of discussion of the feature itself
and (if you're proposing code as well) the implementation of the feature.

### Bug Fixes

If you've identified a significant bug, or one that you don't intend to fix yourself,
please write up an issue ticket describing the problem.
For minor or straightforward bug fixes, feel free to proceed directly to a PR.

### Pull Request Tips

To speed up reviews, it's helpful if you enable edits from maintainers when opening the PR.
In the case of minor changes, formatting, or style nitpicks, we can make edits directly to avoid wasting your time.
In order to enable edits from maintainers, **you'll need to make the PR from a fork owned an individual**,
not an organization. GitHub org-owned forks lack this flexibility.

Note: we enforce formatting checks on PRs.
If you forget to do this, CI will eventually fail on your PR.

## How to Approach a Contribution

Before you beign, review the architecture of the project in our [architecture](docs/src/architecture.md) doc. This is helpful to understand
the stack and where your contribution fits in.

### For the Wrapper (in src/)

1. Determine the minimum valhalla c++ to accomplish your goal. This typically means searching the valhalla src
directory for the entry point of the server endpoint. In the case of route generation this was the valhalla actor.
2. Write a c++ function that takes a Valhalla config and simple args and returns simple arg(s) (typically json strings
since valhalla supports web servers). See [`ValhallaActor::route`](src/wrapper/valhalla_actor.cpp).

### For iOS (in apple/)

1. Apple more directly supports c++, but we still need a wrapper to catch C++ exceptions (same as the JNI, but much cleaner). See: [`route`](src/wrapper/main.cpp#L47)
2. We make use of the function in the Objective C++ layer (this is likely to go away now that Swift-C++ interop is available)
3. Build a wrapper function that makes use of the OpenAPI codables.
4. Test that Swift function to make sure the expected behavior is working at the Swift level.

### For Android (in android/)

1. Write the JNI wrapper: [`Java_com_valhalla_valhalla_ValhallaKotlin_route`](src/wrapper/main.cpp#L14). JNI looks a lot worse than it is,
especially with AI assistance. Make sure to capture errors and return them in the string. This avoids c++
crashing the app with an uncaught exception.
2. Expose the JNI function in the kotlin JNI loader. See: [`ValhallaKotlin.kt#L10`](android/valhalla/src/main/java/com/valhalla/valhalla/ValhallaKotlin.kt#L10)
3. Build a nice Kotlin function that cleanly implements the behavior. [`Valhalla.kt#L12`](android/valhalla/src/main/java/com/valhalla/valhalla/Valhalla.kt#L12)
4. Test that Kotlin function to make sure the expected behavior is working at the Kotlin level.

### For Other Platforms

We're open to adding other platforms that can access the iOS or Android `libvalhalla_wrapper.a` or `libvalhalla_wrapper.so` files directly. 
However, it may be easier to just interact with the Swift and Kotlin code directly. If you're interested in adding a new platform, please open an issue.
