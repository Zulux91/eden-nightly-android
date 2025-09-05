#!/bin/bash

set -ex

echo "Generating changelog for release"

# Clone Eden, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
	echo "Using mirror instead..."
	rm -rf ./eden || true
	git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi
cd ./eden

# Get current commit info
COUNT="$(git rev-list --count HEAD)"
DATE="$(date +"%Y-%m-%d")"
TAG="${DATE}-${COUNT}"
SOURCE_NAME="Eden-${COUNT}-Source-Code"
echo "$TAG" > ~/tag
echo "$COUNT" > ~/count

# Start to generate release info and changelog
CHANGELOG_FILE=~/changelog
BASE_COMMIT_URL="https://git.eden-emu.dev/eden-emu/eden/commit"
BASE_COMPARE_URL="https://git.eden-emu.dev/eden-emu/eden/compare"
BASE_DOWNLOAD_URL="https://github.com/Zulux91/eden-nightly-android/releases/download"

# Fallback if OLD_COUNT is empty or null
if [ -z "$OLD_COUNT" ] || [ "$OLD_COUNT" = "null" ]; then
  echo "OLD_COUNT is empty, falling back to current COUNT"
  OLD_COUNT="$COUNT"
fi
OLD_HASH=$(git rev-list --reverse HEAD | sed -n "${OLD_COUNT}p")
i=$((OLD_COUNT + 1))

# Add reminder and Release Overview link
echo ">[!WARNING]" > "$CHANGELOG_FILE"
echo "**This repository is not affiliated with the official Eden development team. It exists solely to provide an easy way for users to try out the latest features from recent commits.**" >> "$CHANGELOG_FILE"
echo "**These builds are experimental and may be unstable. Use them at your own risk, and please do not report issues from these builds to the official channels unless confirmed on official releases.**" >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"
echo "> [!IMPORTANT]" >> "$CHANGELOG_FILE"
echo "> See the **[Release Overview](https://github.com/Zulux91/eden-nightly-android?tab=readme-ov-file#release-overview)** section for detailed differences between each apk." >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"

# Add changelog section
echo "## Changelog:" >> "$CHANGELOG_FILE"
git log --reverse --pretty=format:"%H %s" "${OLD_HASH}..HEAD" | while IFS= read -r line || [ -n "$line" ]; do
  full_hash="${line%% *}"
  msg="${line#* }"
  short_hash="$(git rev-parse --short "$full_hash")"
  echo -e "- Merged commit: \`${i}\` [\`${short_hash}\`](${BASE_COMMIT_URL}/${full_hash})\n  ${msg}" >> "$CHANGELOG_FILE"
  echo >> "$CHANGELOG_FILE"
  i=$((i + 1))
done

# Add full changelog from lastest official tag release
echo "Full Changelog: [\`v0.0.3...master\`](${BASE_COMPARE_URL}/v0.0.3...master)" >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"

# Generate release table
echo "## Unofficial Nightly Release: ${COUNT}" >> "$CHANGELOG_FILE"
echo "| Platform | Target / Arch |" >> "$CHANGELOG_FILE"
echo "|--|--|" >> "$CHANGELOG_FILE"
echo "| Android | [\`Coexist\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-Unofficial-Coexist.apk)<br><br>[\`Replace\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-Unofficial-Replace.apk)<br><br>[\`Optimised\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-Unofficial-Optimised.apk) |" >> "$CHANGELOG_FILE"
echo "| Any | [Source Code](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Source-Code.7z) |" >> "$CHANGELOG_FILE"

# Pack up source for upload
cd ..
mkdir -p artifacts
mkdir "$SOURCE_NAME"
cp -a eden/. "$SOURCE_NAME"
ZIP_NAME="$SOURCE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$SOURCE_NAME"
mv "$ZIP_NAME" artifacts/