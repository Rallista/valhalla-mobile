#!/usr/bin/env bash
#
# Regenerates the bundled default valhalla config from the pinned submodule.
#
# The config both platforms start from is not hand-written: it is the output of
# valhalla's own `scripts/valhalla_build_config`, so it tracks whatever version
# `src/valhalla` is pinned to. Run this after bumping the submodule — a release
# that adds, removes, or re-defaults a config key is otherwise invisible until
# something misbehaves at runtime.
#
# Both platforms read the same bytes: iOS bundles it as an SPM resource, Android
# as a java resource on the classpath. Writing both from one generator is what
# keeps the two defaults from drifting apart.
#
# Usage:
#   scripts/generate_default_config.sh           # rewrite the checked-in copies
#   scripts/generate_default_config.sh --check   # fail if they are out of date (CI)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR="${REPO_ROOT}/src/valhalla/scripts/valhalla_build_config"

# Both destinations are byte-for-byte identical. See the note above.
APPLE_CONFIG="${REPO_ROOT}/apple/Sources/Valhalla/SupportData/default.json"
ANDROID_CONFIG="${REPO_ROOT}/android/valhalla/src/main/resources/com/valhalla/valhalla/default.json"

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=true
elif [[ $# -gt 0 ]]; then
    echo "usage: $(basename "$0") [--check]" >&2
    exit 2
fi

if [[ ! -f "${GENERATOR}" ]]; then
    echo "error: ${GENERATOR} not found." >&2
    echo "The valhalla submodule is not checked out. Run:" >&2
    echo "    git submodule update --init --recursive" >&2
    exit 1
fi

# valhalla_build_config uses PEP 604 unions (`list[str] | None`) at runtime,
# which need 3.10+. macOS still ships 3.9 as `python3`, so probe for a usable
# interpreter rather than failing with an opaque TypeError from inside the script.
PYTHON=""
for candidate in python3 python3.13 python3.12 python3.11 python3.10; do
    if command -v "${candidate}" >/dev/null 2>&1 &&
        "${candidate}" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
        PYTHON="${candidate}"
        break
    fi
done

if [[ -z "${PYTHON}" ]]; then
    echo "error: python 3.10 or newer is required to run valhalla_build_config." >&2
    exit 1
fi

# No flags: the pristine defaults for the pinned valhalla version.
#
# Do not pass path overrides here. The placeholder paths this emits
# (mjolnir.tile_dir, mjolnir.admin, mjolnir.timezone) point at server locations
# that exist on no device, and every one that matters is replaced at runtime by
# the platform config builders. Overriding them by hand is what let the file
# drift away from being reproducible in the first place.
GENERATED="$(mktemp)"
trap 'rm -f "${GENERATED}"' EXIT

"${PYTHON}" "${GENERATOR}" > "${GENERATED}"

# Normalise the formatting so a diff only ever shows a real config change.
FORMATTED="$(mktemp)"
trap 'rm -f "${GENERATED}" "${FORMATTED}"' EXIT
"${PYTHON}" -c '
import json, sys
with open(sys.argv[1]) as f:
    config = json.load(f)
with open(sys.argv[2], "w") as f:
    json.dump(config, f, indent=2, sort_keys=False)
    f.write("\n")
' "${GENERATED}" "${FORMATTED}"

VALHALLA_VERSION="$(cd "${REPO_ROOT}/src/valhalla" && git describe --tags --always 2>/dev/null || echo "unknown")"

if [[ "${CHECK_ONLY}" == true ]]; then
    status=0
    for destination in "${APPLE_CONFIG}" "${ANDROID_CONFIG}"; do
        if [[ ! -f "${destination}" ]]; then
            echo "error: ${destination#"${REPO_ROOT}/"} is missing." >&2
            status=1
        elif ! diff -u "${destination}" "${FORMATTED}" > /dev/null; then
            echo "error: ${destination#"${REPO_ROOT}/"} is out of date for valhalla ${VALHALLA_VERSION}." >&2
            diff -u "${destination}" "${FORMATTED}" >&2 || true
            status=1
        fi
    done
    if [[ ${status} -eq 0 ]]; then
        echo "default config is up to date for valhalla ${VALHALLA_VERSION}."
    else
        echo "Run scripts/generate_default_config.sh to update it." >&2
    fi
    exit ${status}
fi

for destination in "${APPLE_CONFIG}" "${ANDROID_CONFIG}"; do
    mkdir -p "$(dirname "${destination}")"
    cp "${FORMATTED}" "${destination}"
    echo "wrote ${destination#"${REPO_ROOT}/"}"
done

echo "default config regenerated from valhalla ${VALHALLA_VERSION}."
