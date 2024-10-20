#!/bin/bash

# Get the last version from the version.txt file (X.Y.Z)
last_version=$(cat version.txt)

# Determine the next version based on the last tag and the desired version
# bump type in argument 1
if [ "$1" == "major" ]; then
    next_version=$(echo $last_version | awk -F. '{print $1+1".0.0"}')
elif [ "$1" == "minor" ]; then
    next_version=$(echo $last_version | awk -F. '{print $1"."$2+1".0"}')
elif [ "$1" == "patch" ]; then
    next_version=$(echo $last_version | awk -F. '{print $1"."$2"."$3+1}')
else
    echo "Invalid version bump type. Please use 'major', 'minor', or 'patch'."
    exit 1
fi

echo "Bumping version from $last_tag to $next_version"

# Write the version to the version.txt file
echo "$next_version" > version.txt

# Output the tag to stdout
echo ::set-output name=version::$next_version
