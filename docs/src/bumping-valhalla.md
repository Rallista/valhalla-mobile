# Upgrading Valhalla

When a new valhalla release comes out at <https://github.com/valhalla/valhalla/releases>.

```sh
# Clean up valhalla submodule (important this is not concurrent.)
git submodule deinit -f src/valhalla
git rm --cached src/valhalla
rm -rf src/valhalla
rm -rf .git/modules/src/valhalla

# Checkout the latest release branch
git submodule add git@github.com:valhalla/valhalla.git src/valhalla
cd src/valhalla && git checkout 3.6.1 # Replace with the latest version tag release

# Install recursive submodules now that the exact version of valhalla is selected.
git submodule update --init --recursive
```

At this point valhalla's src folder has been updated and prepared. 
Now it's time to test if the existing `src/CMakeLists.txt` still builds by running
an iOS and Android build.
