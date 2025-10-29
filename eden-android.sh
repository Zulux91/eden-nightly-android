#!/bin/bash -ex

cd ./eden

# hook the updater to check my repo
git apply ../patches/update.patch

if [ "$TARGET" = "Coexist" ]; then
    # Change the App name and application ID to make it coexist with official build, and use different launcher icon
    git apply ../patches/coexist.patch
fi

COUNT="$(git rev-list --count HEAD)"
APK_NAME="Eden-${COUNT}-Android-${TARGET}"

cd src/android
chmod +x ./gradlew
if [ "$TARGET" = "Optimized" ]; then
	./gradlew assembleGenshinSpoofRelease -PYUZU_ANDROID_ARGS="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DENABLE_UPDATE_CHECKER=ON"
elif [ "$TARGET" = "Legacy" ]; then
	./gradlew assembleLegacyRelease -PYUZU_ANDROID_ARGS="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DENABLE_UPDATE_CHECKER=ON"
else
	./gradlew assembleMainlineRelease -PYUZU_ANDROID_ARGS="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DENABLE_UPDATE_CHECKER=ON"
fi
ccache -s -v

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"