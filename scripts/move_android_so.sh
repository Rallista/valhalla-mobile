#/bin/sh

# Move the Android .so files to the correct directory
mv build/android/arm64-v8a/wrapper/wrapper/libvalhalla_wrapper.so src/android/jniLibs/arm64-v8a/
mv build/android/armeabi-v7a/wrapper/wrapper/libvalhalla_wrapper.so src/android/jniLibs/armeabi-v7a/
mv build/android/x86_64/wrapper/wrapper/libvalhalla_wrapper.so src/android/jniLibs/x86_64/
mv build/android/x86/wrapper/wrapper/libvalhalla_wrapper.so src/android/jniLibs/x86/