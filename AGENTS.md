# AGENTS.md — AI Tool Guidance for valhalla-mobile

This file describes conventions and critical process steps for AI coding assistants
(Claude, Copilot, Cursor, etc.) contributing to this repository.

## Bumping the Valhalla Submodule

Follow `docs/src/bumping-valhalla.md` exactly. The most common mistake is recording
the wrong submodule commit. Here is the safe sequence:

```sh
# 1. Remove the old submodule completely
git submodule deinit -f src/valhalla
git rm --cached src/valhalla
rm -rf src/valhalla
rm -rf .git/modules/src/valhalla

# 2. Re-add — this records valhalla's default branch HEAD in the index
git submodule add https://github.com/valhalla/valhalla.git src/valhalla

# 3. Check out the release tag inside the submodule working tree
cd src/valhalla
git checkout <TAG>          # e.g. git checkout 3.6.3
cd ../..

# 4. CRITICAL: re-stage the submodule so the parent records the tag commit, not HEAD
git add src/valhalla
# Verify the recorded SHA matches the tag before continuing:
git submodule status        # should show e2f017b... for 3.6.3

# 5. Initialize valhalla's own recursive submodules
git submodule update --init --recursive

# 6. Update version references
#    - README.md version badge
#    - version.txt (if present)
```

**Why step 4 matters**: `git submodule add` records whatever commit the remote's
default branch points to. Checking out the tag in step 3 only moves the working
tree — it does not update the gitlink in the parent index. Without step 4 the
commit stored in the parent is the default branch HEAD, not the release tag.

## Commit Format

- Follow conventional commits: `chore:`, `fix:`, `feat:`, `docs:`
- Include AI disclosure footer per project policy:
  `Co-Authored-By: Claude and aki1770-del <aki1770@gmail.com>`

## PR Guidelines

See `CONTRIBUTING.md`. Key points for AI-generated contributions:

- Enable maintainer edits (use a personal fork, not an org fork)
- Every PR must reference a filed issue
- The human author (Komada) writes the PR title, description, and any
  maintainer-facing communication — AI assists with code only
