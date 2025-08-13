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
import os, cmake
# El binario queda en <site-packages>/cmake/data/bin/cmake
print(os.path.join(os.path.dirname(cmake.__file__), "data"))
PY
)"

if [ -z "${PY_CMAKE_DIR:-}" ]; then
    echo "No se pudo localizar la CMake instalada por pip" >&2
    exit 1
fi

# 3) (Opcional) Garantizar que haya un 'ninja' accesible en esa CMake
mkdir -p "${PY_CMAKE_DIR}/bin"
USER_BIN="$(python3 -c 'import site, os; print(os.path.join(site.getuserbase(), "bin"))')"
if [ -x "${USER_BIN}/ninja" ]; then
    ln -sfn "${USER_BIN}/ninja" "${PY_CMAKE_DIR}/bin/ninja"
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
mkdir -p "${ANDROID_SDK_ROOT}/cmake"
ln -sfn "${PY_CMAKE_DIR}" "${ANDROID_SDK_ROOT}/cmake/3.22.1"
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