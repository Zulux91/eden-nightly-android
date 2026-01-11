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

# Set extra cmake flags
CMAKE_FLAGS=(
    "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
    "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
    "-DENABLE_UPDATE_CHECKER=ON"
)

echo "-- Extra CMake Flags:"
for flag in "${CMAKE_FLAGS[@]}"; do
    echo "  $flag"
done

# Set flavor for gradle build
case "$TARGET" in
	Optimized)
		FLAVOR="GenshinSpoof"
	;;
	Legacy)
		FLAVOR="Legacy"
	;;
	ChromeOS)
		FLAVOR="ChromeOS"
	;;
	*)
		FLAVOR="Mainline"
	;;
esac

echo "-- Starting Gradle build..."
cd src/android
chmod +x ./gradlew
./gradlew "assemble${FLAVOR}Release" -PYUZU_ANDROID_ARGS="${CMAKE_FLAGS[*]}"

echo "-- Ccache stats:"
ccache -s -v

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
echo "-- Found APK at: $APK_PATH"

mkdir -p artifacts
mv -v "$APK_PATH" "artifacts/$APK_NAME.apk"

echo "=== ALL DONE! ==="