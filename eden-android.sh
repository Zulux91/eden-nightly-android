#!/bin/bash -ex

cd ./eden

if [ "$TARGET" = "Coexist" ]; then
    # Change the App name and application ID to make it coexist with official build
    sed -i 's/applicationId = "dev\.eden\.eden_emulator"/applicationId = "dev.eden.eden_nightly"/' src/android/app/build.gradle.kts
    sed -i 's/resValue("string", "app_name_suffixed", "Eden")/resValue("string", "app_name_suffixed", "Eden Nightly")/' src/android/app/build.gradle.kts
fi

COUNT="$(git rev-list --count HEAD)"
APK_NAME="Eden-${COUNT}-Android-${TARGET}"

cd src/android
chmod +x ./gradlew
if [ "$TARGET" = "Optimized" ]; then
	./gradlew assembleGenshinSpoofRelease
elif [ "$TARGET" = "Legacy" ]; then
	./gradlew assembleLegacyRelease
else
	./gradlew assembleMainlineRelease
fi

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"