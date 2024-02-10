#/bin/sh

# Get the last git tag/release that matches the release pattern (vX.Y.Z)
last_tag=$(git describe --tags --match "v[0-9]*.[0-9]*.[0-9]*" --abbrev=0)

# Determine the next version based on the last tag and the desired version bump type in argument 1
if [ "$1" == "major" ]; then
    next_version=$(echo $last_tag | awk -F. '{print $1+1".0.0"}')
elif [ "$1" == "minor" ]; then
    next_version=$(echo $last_tag | awk -F. '{print $1"."$2+1".0"}')
elif [ "$1" == "patch" ]; then
    next_version=$(echo $last_tag | awk -F. '{print $1"."$2"."$3+1}')
else
    echo "Invalid version bump type. Please use 'major', 'minor', or 'patch'."
    exit 1
fi

echo "Bumping version from $last_tag to $next_version"

# Output the tag to stdout
echo ::set-output name=version::$next_version