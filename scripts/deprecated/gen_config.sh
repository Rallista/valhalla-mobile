#/bin/sh

mkdir -p apple/Sources/Generated/Config
quicktype apple/Tests/TestData/config.json \
    --access-level public --top-level ValhallaConfig \
    -o apple/Sources/Generated/Config/ValhallaConfig.swift