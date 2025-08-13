#!/bin/bash -ex

export NDK_CCACHE=$(which sccache)

cd ./eden

# --- BEGIN: Pin de CMake desde el script (sin tocar Gradle/CI) ---
: "${ANDROID_SDK_ROOT:=${ANDROID_HOME:-/usr/local/lib/android/sdk}}"
SDKMANAGER="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

# Instalar CMake 3.27.2 (silencioso) y aceptar licencias
if [ -x "$SDKMANAGER" ]; then
    yes | "$SDKMANAGER" "cmake;3.27.2" >/dev/null || true
    yes | "$SDKMANAGER" --licenses >/dev/null || true
fi

CMAKE_DIR="$ANDROID_SDK_ROOT/cmake/3.27.2"

# Forzar a Gradle/AGP a usar esa CMake mediante local.properties
# (se crea/actualiza en tiempo de ejecución, no modifica el repo)
if [ -d "$CMAKE_DIR" ]; then
    if [ -f local.properties ]; then
        if grep -q '^cmake\.dir=' local.properties; then
            sed -i "s|^cmake\.dir=.*|cmake.dir=$CMAKE_DIR|" local.properties
        else
            echo "cmake.dir=$CMAKE_DIR" >> local.properties
        fi
    else
        echo "cmake.dir=$CMAKE_DIR" > local.properties
    fi
else
    echo "ADVERTENCIA: No se encontró $CMAKE_DIR; se intentará con la CMake por defecto del SDK."
fi

# (Opcional, sólo si siguiera insistiendo en 3.22.1)
# ln -sfn "$CMAKE_DIR" "$ANDROID_SDK_ROOT/cmake/3.22.1" || true
# --- END: Pin de CMake ---


# don't build tests and build real release type
sed -i '/"-DYUZU_ENABLE_LTO=ON"/a\
                    "-DCMAKE_C_COMPILER_LAUNCHER=sccache",\
                    "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache",
' src/android/app/build.gradle.kts

if [ "$TARGET" = "Coexist" ]; then
    # Change the App name and application ID to make it coexist with official build
    sed -i 's/applicationId = "dev\.eden\.eden_emulator"/applicationId = "dev.eden.eden_emulator.nightly"/' src/android/app/build.gradle.kts
    sed -i 's/resValue("string", "app_name_suffixed", "Eden")/resValue("string", "app_name_suffixed", "Eden Nightly")/' src/android/app/build.gradle.kts
    sed -i 's|<string name="app_name"[^>]*>.*</string>|<string name="app_name" translatable="false">Eden Nightly</string>|' src/android/app/src/main/res/values/strings.xml
fi        

if [ "$TARGET" = "Optimised" ]; then
    # Add optimised to the app home screen
    sed -i 's/resValue("string", "app_name_suffixed", "Eden")/resValue("string", "app_name_suffixed", "Eden Optimised")/' src/android/app/build.gradle.kts
    sed -i 's|<string name="app_name"[^>]*>.*</string>|<string name="app_name" translatable="false">Eden Optimised</string>|' src/android/app/src/main/res/values/strings.xml
fi 

COUNT="$(git rev-list --count HEAD)"
APK_NAME="Eden-${COUNT}-Android-Unofficial-${TARGET}"

cd src/android
chmod +x ./gradlew
if [ "$TARGET" = "Optimised" ]; then
	./gradlew assembleGenshinSpoofRelease --parallel --console=plain --info
else
	./gradlew assembleMainlineRelease --parallel --console=plain --info
fi

sccache -s

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
if [ -z "$APK_PATH" ]; then
    echo "Error: APK not found in expected directory."
    exit 1
fi
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"