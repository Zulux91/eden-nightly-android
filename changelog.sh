#!/bin/bash

set -e

echo "-- Generating changelog for release..."

echo "-- Cloning Eden repository..."
git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden
cd ./eden
echo "   Done."

# Get current commit info
echo "-- Setup release information..."
COUNT="$(git rev-list --count HEAD)"
DATE="$(date +"%Y-%m-%d")"
TAG="${DATE}-${COUNT}"

echo "$TAG" > ~/tag
echo "$COUNT" > ~/count
echo "   Release tag: $TAG"
echo "   Commit count: $COUNT"

# Start to generate release info and changelog
CHANGELOG_FILE=~/changelog
BASE_COMMIT_URL="https://git.eden-emu.dev/eden-emu/eden/commit"
BASE_COMPARE_URL="https://git.eden-emu.dev/eden-emu/eden/compare"
BASE_DOWNLOAD_URL="https://github.com/Zulux91/eden-nightly-android/releases/download"

# Fallback if OLD_COUNT is empty or null
echo "-- Checking previous release count..."
if [ -z "$OLD_COUNT" ] || [ "$OLD_COUNT" = "null" ]; then
  echo "   OLD_COUNT is empty, assuming first release. Initializing to $((COUNT - 1))"
  OLD_COUNT=$((COUNT - 1))
  OLD_HASH=$(git rev-parse HEAD~1)
else
  echo "   Previous release count found: $OLD_COUNT"
  OLD_HASH=$(git rev-list --reverse HEAD | sed -n "${OLD_COUNT}p")
fi
i=$((OLD_COUNT + 1))

# Add reminder and Release Overview link
echo "-- Generating changelog file..."
echo ">[!WARNING]" > "$CHANGELOG_FILE"
echo "**This repository is not affiliated with the official Eden development team. It exists solely to provide an easy way for users to try out the latest features from recent commits.**" >> "$CHANGELOG_FILE"
echo "**These builds are experimental and may be unstable. Use them at your own risk, and please do not report issues from these builds to the official channels unless confirmed on official releases.**" >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"
echo "> [!IMPORTANT]" >> "$CHANGELOG_FILE"
echo "> See the **[Release Overview](https://github.com/Zulux91/eden-nightly-android?tab=readme-ov-file#release-overview)** section for detailed differences between each apk." >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"

# Add changelog section
echo "## Changelog:" >> "$CHANGELOG_FILE"
git log --reverse --pretty=format:"%H%x09%s%x09%an" "${OLD_HASH}..HEAD" |
while IFS=$'\t' read -r full_hash msg author || [ -n "$full_hash" ]; do
  short_hash="$(git rev-parse --short "$full_hash")"
  echo -e "- Merged commit: \`${i}\` [\`${short_hash}\`](${BASE_COMMIT_URL}/${full_hash}) by **${author}**\n  ${msg}" >> "$CHANGELOG_FILE"
  echo >> "$CHANGELOG_FILE"
  i=$((i + 1))
done

# Add full changelog from lastest official tag release
echo "Full Changelog: [\`v0.0.4...master\`](${BASE_COMPARE_URL}/v0.0.4...master)" >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"
echo "   - Added changelog section."

# Generate release table
echo "## Unofficial Nightly Release: ${COUNT}" >> "$CHANGELOG_FILE"
echo "| Platform | Target / Arch |" >> "$CHANGELOG_FILE"
echo "|--|--|" >> "$CHANGELOG_FILE"
echo "| Android | [\`Replace\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-Replace.apk)<br><br>\
[\`Coexist\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-Coexist.apk)<br><br>\
[\`Optimised\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-Optimised.apk)<br><br>\
[\`ChromeOS\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-ChromeOS.apk)<br><br>\
[\`Legacy\`](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Android-Legacy.apk) |" >> "$CHANGELOG_FILE"
echo "| Any | [Source Code](${BASE_DOWNLOAD_URL}/${TAG}/Eden-${COUNT}-Source-Code.7z) |" >> "$CHANGELOG_FILE"
echo "   - Added release table."

echo "-- Full changelog generated:"
cat "$CHANGELOG_FILE"

echo "=== ALL DONE! ==="