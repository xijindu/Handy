#!/usr/bin/env bash
set -euo pipefail

mode="${1:-minor}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pubspec_file="${PUBSPEC_FILE:-"$script_dir/../pubspec.yaml"}"

usage() {
  cat <<'EOF'
Usage: tool/bump_version.sh [major|minor|all]

major  Bump app version patch: 0.8.94 -> 0.8.95
minor  Bump build number by one: 0.8.94+1 -> 0.8.94+2 (default)
all    Bump both app version patch and build number
EOF
}

if [[ "$mode" != "major" && "$mode" != "minor" && "$mode" != "all" ]]; then
  usage >&2
  exit 64
fi

version_line="$(grep -E '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$' "$pubspec_file" || true)"
if [[ -z "$version_line" ]]; then
  echo "No valid version line found in $pubspec_file" >&2
  exit 1
fi

version="${version_line#version: }"
app_version="${version%%+*}"
build_number="${version##*+}"

if [[ "$mode" == "major" || "$mode" == "all" ]]; then
  IFS='.' read -r major minor patch <<<"$app_version"
  patch=$((patch + 1))
  app_version="$major.$minor.$patch"
fi

if [[ "$mode" == "minor" || "$mode" == "all" ]]; then
  # The build number is a plain counter, so it has to grow by one every release.
  build_number=$((10#$build_number + 1))
fi

new_version="$app_version+$build_number"
tmp_file="$(mktemp)"
sed "s/^version: .*/version: $new_version/" "$pubspec_file" >"$tmp_file"
mv "$tmp_file" "$pubspec_file"

echo "$version -> $new_version"
