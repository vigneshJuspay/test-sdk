set -euo pipefail
export LC_ALL=C

doc="${ERROR_CODES_DOC:-docs/error-codes.md}"
codes_file="${CODES_FILE:-PeekKit/Classes/PeekErrorCodes.swift}"

for file in "$doc" "$codes_file"; do
  if [ ! -f "$file" ]; then
    echo "$file not found; run this from the repository root" >&2
    exit 1
  fi
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

sed -nE '/^[[:space:]]*\/\//d; s/.*static let [A-Za-z_][A-Za-z0-9_]*[[:space:]]*(:[[:space:]]*String)?[[:space:]]*=[[:space:]]*"([A-Z0-9_]+)".*/\2/p' "$codes_file" | sort -u > "$work/sdk"

awk -v rows="$work/rows" -v passthrough="$work/passthrough" '
  BEGIN { printf "" > rows; printf "" > passthrough }
  /^<!-- passthrough-error-codes[ \t]*$/ { in_list = 1; next }
  in_list && /-->/ { in_list = 0; next }
  in_list { gsub(/^[ \t]+|[ \t]+$/, ""); if ($0 ~ /^[A-Z0-9_]+$/) print $0 > passthrough; next }
  /^\| *Code *\|/ { found = 1; next }
  found && match($0, /^\| *`[A-Z0-9_]+`/) { code = substr($0, RSTART, RLENGTH); gsub(/[| `]/, "", code); print code > rows }
  END { if (!found) { printf "%s: no table with a Code column\n", FILENAME > "/dev/stderr"; exit 1 } }
' "$doc"
status=0
fail() { echo "$1" >&2; status=1; }
for code in $(sort "$work/rows" | uniq -d); do
  fail "$doc: $code has more than one row in the table"
done
for code in $(sort "$work/passthrough" | uniq -d); do
  fail "$doc: $code is in the passthrough list more than once"
done

sort -u -o "$work/rows" "$work/rows"
sort -u -o "$work/passthrough" "$work/passthrough"
sort -u "$work/sdk" "$work/passthrough" > "$work/known"

for code in $(comm -23 "$work/sdk" "$work/rows"); do
  fail "$codes_file: $code is sent by the SDK but has no row in $doc"
done
for code in $(comm -23 "$work/passthrough" "$work/rows"); do
  fail "$doc: $code is in the passthrough list but has no row in the table"
done
for code in $(comm -23 "$work/rows" "$work/known"); do
  fail "$doc: $code has a row, but it is neither in $codes_file nor in the passthrough list"
done
for code in $(comm -12 "$work/sdk" "$work/passthrough"); do
  fail "$doc: $code is in the passthrough list, but $codes_file defines it as an SDK code"
done
if [ "$status" -ne 0 ]; then
  exit 1
fi

echo "$(wc -l < "$work/rows" | tr -d ' ') error codes in $doc match $codes_file and the passthrough list."
