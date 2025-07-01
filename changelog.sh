#!/bin/bash
set -ex

echo "Generating Android-only changelog for release"

# Clone Eden, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
    echo "Using mirror instead..."
    rm -rf ./eden || true
    git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi
cd ./eden

# Get commit/tag info
COUNT="$(git rev-list --count HEAD)"
DATE="$(date +"%Y-%m-%d")"
HASH="$(git rev-parse --short HEAD)"
TAG="${DATE}-${HASH}"
SOURCE_NAME="Eden-${COUNT}-Source-Code"
echo "$TAG" > ~/tag
echo "$COUNT" > ~/count

# Setup changelog
CHANGELOG_FILE=~/changelog
BASE_COMMIT_URL="https://git.eden-emu.dev/eden-emu/eden/commit"

if [ -z "$OLD_HASH" ]; then
    echo "OLD_HASH is empty, falling back to current HASH"
    OLD_HASH="$HASH"
fi
START_COUNT=$(git rev-list --count "$OLD_HASH")
i=$((START_COUNT + 1))

# Changelog header
echo ">[!WARNING]" > "$CHANGELOG_FILE"
echo "**This unofficial nightly build contains only Android-related changes. Use at your own risk.**" >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"
echo "## Android-related changes:" >> "$CHANGELOG_FILE"

# Filter commits affecting android-related files only
git log --reverse --pretty=format:"%H %s" "${OLD_HASH}..HEAD" -- src/android/ eden/src/android/ eden-android.sh | while IFS= read -r line || [ -n "$line" ]; do
  full_hash="${line%% *}"
  msg="${line#* }"
  short_hash="$(git rev-parse --short "$full_hash")"
  echo -e "- \`${i}\` [\`${short_hash}\`](${BASE_COMMIT_URL}/${full_hash}) ${msg}" >> "$CHANGELOG_FILE"
  echo >> "$CHANGELOG_FILE"
  i=$((i + 1))
done

# Package source
cd ..
mkdir -p artifacts
mkdir "$SOURCE_NAME"
cp -av eden/. "$SOURCE_NAME"
ZIP_NAME="$SOURCE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$SOURCE_NAME"
mv "$ZIP_NAME" artifacts/
echo TAG=$TAG >> $GITHUB_ENV
