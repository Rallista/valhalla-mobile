# Upgrading Valhalla

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
