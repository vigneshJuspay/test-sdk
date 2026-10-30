set -euo pipefail
export LC_ALL=C

repo="${GITHUB_REPOSITORY:-example/test-sdk}"
file="${CHANGELOG:-CHANGELOG.md}"

if [ $# -ne 2 ]; then
  echo "usage: update-changelog.sh <version> <notes-file>" >&2
  exit 2
fi
version=$1
notes=$2

if [ ! -f "$file" ]; then
  echo "$file not found; run this from the repository root" >&2
  exit 1
fi
if [ ! -f "$notes" ]; then
  echo "$notes not found" >&2
  exit 1
fi
if grep -qF "## [$version](" "$file"; then
  echo "$file already has $version" >&2
  exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

day=${CHANGELOG_DATE:-$(date -u +%Y-%m-%d)}
heading="## [$version](https://github.com/$repo/releases/tag/$version) - $day"
awk -v heading="$heading" -v notes="$notes" '
  function release(gap) {
    print heading
    print ""
    while ((getline line < notes) > 0) print line
    if (gap) print ""
    added = 1
  }
  !added && /^## \[/ { release(1) }
  { print }
  END { if (!added) { print ""; release(0) } }' "$file" > "$work/changelog"
cp "$work/changelog" "$file"
