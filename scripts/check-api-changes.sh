set -euo pipefail
export LC_ALL=C

if [ $# -ne 2 ]; then
  echo "usage: check-api-changes.sh <base> <head>" >&2
  exit 2
fi

api=PeekKit/api/PeekKit.api
fork=$(git merge-base "$1" "$2")

if ! git cat-file -e "$fork:$api" 2>/dev/null; then
  echo "$api is new; nothing to compare it with."
  exit 0
fi

changes=$(git diff "$fork" "$2" -- "$api")
removed=$(sed -n 's/^-\([^-]\)/\1/p' <<< "$changes" | grep -Ev '^[[:space:]{}]*$' || true)
added=$(sed -n 's/^+\([^+]\)/\1/p' <<< "$changes" | grep -Ev '^[[:space:]{}]*$' || true)
if [ -z "$removed" ] && [ -z "$added" ]; then
  echo "The public API does not change."
  exit 0
fi

# The same rules as "Determine version" in release.yml, so this passes only when the release gets the bump the API change needs.
subjects=$(git log --format=%s "$1..$2" | sed -E 's/^[A-Z]+-[0-9]+:[[:space:]]*//')
bump=patch
if git log --format=%B "$1..$2" | grep -Eq '^[[:space:]]*BREAKING[- ]CHANGE'; then
  bump=major
elif grep -Eq '^[a-z]+(\([^)]+\))?!:' <<< "$subjects"; then
  bump=major
elif grep -Eq '^feat(\([^)]+\))?:' <<< "$subjects"; then
  bump=minor
fi

# A changed line that cannot break existing code (a parameter gaining a default value, accepting null) is declared with an
# "API-COMPATIBLE:" footer saying why; it then needs a minor release, like new API, instead of a major one.
compatible=false
if git log --format=%B "$1..$2" | grep -Eq '^API-COMPATIBLE:[[:space:]]*[^[:space:]]'; then
  compatible=true
fi

failures=0
if [ -n "$removed" ] && [ "$bump" != major ] && [ "$compatible" = false ]; then
  echo "✗ Removes or changes public API:"
  sed 's/^[[:space:]]*/    /' <<< "$removed"
  echo '  That breaks apps built on the current version, so it needs a major release: add "!" to the commit type and a "BREAKING CHANGE:" footer saying what to change, e.g. "ABC-123: feat!: ..." with "BREAKING CHANGE: Pass the handler you used with setCallback."'
  echo '  If it cannot break existing code (e.g. a parameter gained a default value), make it a feat commit with an "API-COMPATIBLE:" footer saying why instead.'
  failures=$((failures + 1))
elif [ "$bump" = patch ]; then
  if [ -n "$removed" ]; then echo "✗ Changes public API (API-COMPATIBLE):"; else echo "✗ Adds public API:"; fi
  sed 's/^[[:space:]]*/    /' <<< "${added:-$removed}"
  echo '  New API needs a minor release: make it a feat commit, e.g. "ABC-123: feat: ...".'
  failures=$((failures + 1))
fi

if [ "$failures" -ne 0 ]; then
  echo "$failures problem(s). Fix the commit message (git commit --amend) and push again." >&2
  exit 1
fi
echo "The commits make this a $bump release, which covers the public API change."
