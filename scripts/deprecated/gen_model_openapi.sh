#/bin/sh

apple_generated_dir="apple/Sources/Generated"
android_generated_dir="android/valhalla/src/main/java/com/valhalla/generated"

if [ "$1" == "clean" ]; then
    echo "Cleaning openapi models..."
    rm -rf .openapi-temp
    rm -rf "$apple_generated_dir/Models"
    rm -rf android/valhalla/src/main/java/com/valhalla/models
fi


mkdir -p .openapi-temp
mkdir -p $apple_generated_dir/Models/Support
mkdir -p $android_generated_dir/models/support

echo "Generating Valhalla Swift..."

openapi-generator generate -i ./openapi.yaml -g swift5 --strict-spec=true \
     -o .openapi-temp --model-package Models --skip-validate-spec
swiftformat .openapi-temp/OpenAPIClient/Classes/OpenAPIsModels

# Move the generated files to the correct directory
mv .openapi-temp/OpenAPIClient/Classes/OpenAPIsModels/* $apple_generated_dir/Models
mv .openapi-temp/OpenAPIClient/Classes/OpenAPIs/Models.swift $apple_generated_dir/Models/Support/Models.swift
mv .openapi-temp/OpenAPIClient/Classes/OpenAPIs/Validation.swift $apple_generated_dir/Models/Support/Validation.swift

echo "Generating Valhalla Kotlin..."

openapi-generator generate -i ./openapi.yaml -g kotlin --strict-spec=true \
     -o .openapi-temp --model-package Models --skip-validate-spec -p useKotlinStandardLibrary=true

mv .openapi-temp/src/main/kotlin/Models/* $android_generated_dir/models

echo "Done"

