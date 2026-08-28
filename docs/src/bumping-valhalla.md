# Upgrading Valhalla

When a new valhalla release comes out at <https://github.com/valhalla/valhalla/releases>.

```sh
# Clean up valhalla submodule (important this is not concurrent.)
git submodule deinit -f src/valhalla
git rm --cached src/valhalla
rm -rf src/valhalla
rm -rf .git/modules/src/valhalla

# Checkout the latest release branch
git submodule add https://github.com/valhalla/valhalla.git src/valhalla
cd src/valhalla && git checkout 3.6.2 # Replace with the latest version tag release

# Install recursive submodules now that the exact version of valhalla is selected.
git submodule update --init --recursive
```

At this point valhalla's src folder has been updated and prepared. 
Now it's time to test if the existing `src/CMakeLists.txt` still builds by running
an iOS and Android build.

## Regenerate the default config

The config both platforms start from is not hand-written. It is the output of valhalla's own
`scripts/valhalla_build_config`, so a release that adds, removes, or re-defaults a config key
changes it. Regenerate it from the submodule you just moved:

```sh
scripts/generate_default_config.sh
```

That writes the same bytes to both platforms:

- `apple/Sources/Valhalla/SupportData/default.json`, bundled as an SPM resource.
- `android/valhalla/src/main/resources/com/valhalla/valhalla/default.json`, a java resource.

Review the diff. A changed value is usually fine; an added or removed key is not, because the
generated config models have to cover every key valhalla writes. A key they do not cover is
dropped in silence — `JSONDecoder` and Moshi both skip what they do not recognise — so the config
that reaches the engine quietly loses that setting. `ValhallaConfigFactoryTest` on Android and
`TestDefaultConfigCoverage` in the models repos are what catch it; run them after regenerating.

When a key is missing, update `openapi.yaml` in
[valhalla-openapi-models-kotlin](https://github.com/Rallista/valhalla-openapi-models-kotlin) and
[valhalla-openapi-models-swift](https://github.com/Rallista/valhalla-openapi-models-swift),
release both, and bump the versions here.

`scripts/generate_default_config.sh --check` fails when the checked-in copies are out of date, and
is what CI runs.

Do not hand-edit `default.json`. The placeholder paths it carries (`mjolnir.tile_dir`,
`mjolnir.admin`, `mjolnir.timezone`) point at server locations that exist on no device, and every
one that matters is replaced at runtime by the platform config builders. Editing them by hand is
what let the file drift away from being reproducible in the first place.
