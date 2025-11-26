#!/bin/bash -e

echo "-- Building Android..."

cd ./eden
COUNT="$(git rev-list --count HEAD)"
APK_NAME="Eden-${COUNT}-Android-${TARGET}"

echo "-- Build Configuration:"
echo "   Target: $TARGET"
echo "   Count: $COUNT"
echo "   APK name: $APK_NAME"

# hook the updater to check my repo
echo "-- Applying updater patch..."
git apply ../patches/update.patch
echo "   Done."

# hook apk fetcher and installer
echo "-- Applying apk fetcher and installer patch..."
git apply ../patches/android.patch
echo "   Done."

if [ "$TARGET" = "Coexist" ]; then
    # Change the App name and application ID to make it coexist with official build
	echo "-- Applying coexist patch..."
    git apply ../patches/coexist.patch
	echo "   Done."
fi        

cd src/android
chmod +x ./gradlew

CMAKE_FLAGS="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DENABLE_UPDATE_CHECKER=ON"
echo "-- Extra CMake Flags:"
echo "   -DCMAKE_C_COMPILER_LAUNCHER=ccache"
echo "   -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
echo "   -DENABLE_UPDATE_CHECKER=ON"

echo "-- Starting Gradle build..."
if [ "$TARGET" = "Optimized" ]; then
	./gradlew assembleGenshinSpoofRelease -PYUZU_ANDROID_ARGS="$CMAKE_FLAGS"
elif [ "$TARGET" = "Legacy" ]; then
	./gradlew assembleLegacyRelease -PYUZU_ANDROID_ARGS="$CMAKE_FLAGS"
else
	./gradlew assembleMainlineRelease -PYUZU_ANDROID_ARGS="$CMAKE_FLAGS"
fi
echo "-- Build Completed."

echo "-- Ccache stats:"
ccache -s -v

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
echo "-- Found APK at: $APK_PATH"

mkdir -p artifacts
mv -v "$APK_PATH" "artifacts/$APK_NAME.apk"

echo "=== ALL DONE! ==="