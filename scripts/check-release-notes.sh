set -euo pipefail
export LC_ALL=C

if [ $# -ne 2 ]; then
  echo "usage: check-release-notes.sh <base> <head>" >&2
  exit 2
fi

types=' feat fix docs style refactor perf test build ci chore revert '
subject_re='^([a-z]+)(\([^)]*\))?(!)?: .+$'
removal_re='[Rr]emoved in v?([0-9]+)'
replacement_re='(^|[^a-z])(use|instead|replace|replaced|migrate)([^a-z]|$)'
latest=$(git tag --list | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || true)
major=${latest%%.*}
major=${major:-0}
failures=0

footer() {
  printf '%s\n' "$2" | awk -v token="$1" '
    function flush() { sub(/[ \t]+$/, "", value); if (on && value != "") print value; on = 0; value = "" }
    $0 ~ "^" token ":" { flush(); on = 1; value = $0; sub("^" token ":[ \t]*", "", value); next }
    on && ($0 ~ /^[ \t]*$/ || $0 ~ /^[A-Za-z][A-Za-z-]*: / || $0 ~ /^BREAKING[ -]CHANGE:/) { flush(); next }
    on { line = $0; gsub(/^[ \t]+|[ \t]+$/, "", line); value = value " " line }
    END { flush() }'
}

fail() {
  echo "✗ $short $subject"
  echo "  $1"
  failures=$((failures + 1))
}

for sha in $(git rev-list --reverse --no-merges "$1..$2"); do
  short=$(git log -1 --format=%h "$sha")
  subject=$(git log -1 --format=%s "$sha" | sed -E 's/^[A-Z]+-[0-9]+:[[:space:]]*//')
  body=$(git log -1 --format=%b "$sha")

  if [[ ! $subject =~ $subject_re ]] || [[ $types != *" ${BASH_REMATCH[1]} "* ]]; then
    fail 'Start the title with a type, e.g. "ABC-123: feat: send an error code when the page fails to load". Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.'
    continue
  fi
  type=${BASH_REMATCH[1]}
  bang=${BASH_REMATCH[3]}

  if [ -n "$bang" ] && [ -z "$(footer 'BREAKING[ -]CHANGE' "$body")" ]; then
    fail 'A breaking change needs a "BREAKING CHANGE:" footer saying what integrators must change, e.g. "BREAKING CHANGE: Pass the handler you used with setCallback."'
  fi

  if grep -Eq '^DEPRECATED:[[:space:]]*$' <<< "$body"; then
    fail '"DEPRECATED:" is empty: say what is deprecated, what to use instead and when it will be removed.'
  fi
  while IFS= read -r deprecated; do
    if [ "$type" != feat ] && [ -z "$bang" ]; then
      fail "\"DEPRECATED: $deprecated\" needs a feat commit: a deprecation is at least a minor release."
    fi
    if ! grep -Eiq "$replacement_re" <<< "$deprecated"; then
      fail "\"DEPRECATED: $deprecated\" must say what to use instead, e.g. \"use onBackPressedDispatcher instead\"."
    fi
    if [[ ! $deprecated =~ $removal_re ]] || [ "${BASH_REMATCH[1]}" -le "$major" ]; then
      fail "\"DEPRECATED: $deprecated\" must name a future major version to remove it in, e.g. \"Removed in $((major + 1)).0\"."
    fi
  done < <(footer DEPRECATED "$body")
done

if [ "$failures" -ne 0 ]; then
  echo "$failures problem(s). Fix the commit message (git commit --amend) and push again." >&2
  exit 1
fi
echo "Commit messages make valid release notes."
