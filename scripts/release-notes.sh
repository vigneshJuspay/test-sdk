set -euo pipefail
export LC_ALL=C

repo="${GITHUB_REPOSITORY:-example/test-sdk}"
sections='breaking feat fix deprecations docs test build refactor perf chore ci style revert other'

if [ $# -ne 3 ]; then
  echo "usage: release-notes.sh <previous-tag> <version> <commit>" >&2
  exit 2
fi
prev=$1
version=$2
to=$3

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

pr_for() {
  gh api "repos/$repo/commits/$1/pulls" --jq '[.[] | select(.merged_at != null)][0].number // empty'
}

read_commit() {
  subject=$(git log -1 --format=%s "$1" | sed -E 's/^[A-Z]+-[0-9]+:[[:space:]]*//')
  body=$(git log -1 --format=%b "$1")
  type='' bang='' desc=''
  local re='^([a-z]+)(\([^)]*\))?(!)?: (.+)$'
  if [[ $subject =~ $re ]]; then
    type=${BASH_REMATCH[1]} bang=${BASH_REMATCH[3]} desc=${BASH_REMATCH[4]}
  fi
}

footer() {
  printf '%s\n' "$2" | awk -v token="$1" '
    function flush() { sub(/[ \t]+$/, "", value); if (on && value != "") print value; on = 0; value = "" }
    $0 ~ "^" token ":" { flush(); on = 1; value = $0; sub("^" token ":[ \t]*", "", value); next }
    on && ($0 ~ /^[ \t]*$/ || $0 ~ /^[A-Za-z][A-Za-z-]*: / || $0 ~ /^BREAKING[ -]CHANGE:/) { flush(); next }
    on { line = $0; gsub(/^[ \t]+|[ \t]+$/, "", line); value = value " " line }
    END { flush() }'
}

sentence() {
  if [ -z "$2" ]; then
    printf '%s' "$1"
    return
  fi
  case $1 in
    *[.!?]) printf '%s %s' "$1" "$2" ;;
    *) printf '%s. %s' "$1" "$2" ;;
  esac
}

title_for() {
  case $1 in
    breaking) echo '⚠ Breaking changes' ;;
    feat) echo 'Features' ;;
    fix) echo 'Bug Fixes' ;;
    deprecations) echo 'Deprecations' ;;
    docs) echo 'Documentation' ;;
    test) echo 'Tests' ;;
    build) echo 'Build System' ;;
    refactor) echo 'Code Refactoring' ;;
    perf) echo 'Performance Improvements' ;;
    chore) echo 'Chores' ;;
    ci) echo 'CI' ;;
    style) echo 'Style' ;;
    revert) echo 'Reverts' ;;
    other) echo 'Other changes' ;;
  esac
}

entries() {
  local link breaking d
  link=" ([#$2](https://github.com/$repo/pull/$2))"
  read_commit "$1"
  if [ -z "$type" ]; then
    printf 'other\t%s%s\n' "$subject" "$link"
  elif [ -n "$bang" ] || printf '%s\n' "$body" | grep -Eq '^BREAKING[ -]CHANGE:'; then
    breaking=$(footer 'BREAKING[ -]CHANGE' "$body" | paste -s -d ' ' -)
    printf 'breaking\t%s%s\n' "$(sentence "$desc" "$breaking")" "$link"
  else
    case $type in
      feat | fix | docs | test | build | refactor | perf | chore | ci | style | revert)
        printf '%s\t%s%s\n' "$type" "$desc" "$link" ;;
      *)
        printf 'other\t%s%s\n' "$subject" "$link" ;;
    esac
  fi
  footer DEPRECATED "$body" | while IFS= read -r d; do
    printf 'deprecations\t%s%s\n' "$d" "$link"
  done
}

render() {
  local printed=0 section lines
  for section in $sections; do
    lines=$(awk -v s="$section" 'index($0, s "\t") == 1 { print "- " substr($0, length(s) + 2) }' "$1")
    [ -n "$lines" ] || continue
    [ "$printed" = 0 ] || echo
    printf '### %s\n\n%s\n' "$(title_for "$section")" "$lines"
    printed=1
  done
}

if ! git rev-parse -q --verify "$to^{commit}" >/dev/null; then
  echo "$to is not a commit" >&2
  exit 1
fi
if [ -n "$prev" ]; then
  if ! git rev-parse -q --verify "$prev^{commit}" >/dev/null; then
    echo "$prev is not a commit" >&2
    exit 1
  fi
  range="$prev..$to"
else
  range="$to"
fi

: > "$work/entries"
for sha in $(git rev-list --reverse --no-merges "$range"); do
  pr=$(pr_for "$sha")
  if [ -z "$pr" ]; then
    echo "skipped, no pull request: $(git log -1 --format='%h %s' "$sha")" >&2
    continue
  fi
  entries "$sha" "$pr" >> "$work/entries"
done

notes=$(render "$work/entries")
if [ -n "$prev" ]; then
  compare=$(printf '**Full diff:** [%s...%s](https://github.com/%s/compare/%s...%s)' "$prev" "$version" "$repo" "$prev" "$version")
  if [ -n "$notes" ]; then
    notes="$notes"$'\n\n'"$compare"
  else
    notes=$compare
  fi
fi
if [ -n "$notes" ]; then
  printf '%s\n' "$notes"
fi
