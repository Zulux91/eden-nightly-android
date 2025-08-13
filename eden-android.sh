#!/bin/bash -ex

export NDK_CCACHE=$(which sccache)

cd ./eden

# --- BEGIN: CMake moderno y local.properties en el lugar correcto ---
set -euo pipefail

ANDROID_PROJECT_DIR="src/android"  # raíz del proyecto Android

# 1) Instalar CMake moderno por pip (y ninja como apoyo)
python3 -m pip install --user --upgrade "cmake==3.27.9" "ninja==1.11.1"

# 2) Detectar la ruta raíz para cmake.dir (carpeta que contiene 'bin/')
PY_CMAKE_DIR="$(python3 - <<'PY'
import cmake, os
bin_dir = os.path.dirname(cmake.cmake_path)      # .../cmake/data/bin
root_dir = os.path.dirname(bin_dir)              # .../cmake/data
print(root_dir)
PY
)"

# 3) (Opcional) Garantizar que haya un 'ninja' accesible en esa CMake
if command -v ninja >/dev/null 2>&1; then
    mkdir -p "${PY_CMAKE_DIR}/bin"
    ln -sfn "$(command -v ninja)" "${PY_CMAKE_DIR}/bin/ninja" || true
fi

# 4) Escribir/actualizar local.properties en la RAÍZ del proyecto Android
LP="${ANDROID_PROJECT_DIR}/local.properties"
if [ -f "${LP}" ]; then
    if grep -q '^cmake\.dir=' "${LP}"; then
        sed -i "s|^cmake\.dir=.*|cmake.dir=${PY_CMAKE_DIR}|" "${LP}"
    else
        echo "cmake.dir=${PY_CMAKE_DIR}" >> "${LP}"
    fi
else
    echo "cmake.dir=${PY_CMAKE_DIR}" > "${LP}"
fi

echo "cmake.dir apuntando a: ${PY_CMAKE_DIR}"
"${PY_CMAKE_DIR}/bin/cmake" --version || true
# --- END ---

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