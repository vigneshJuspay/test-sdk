set -euo pipefail
export LC_ALL=C

api=PeekKit/api/PeekKit.api

if [ "${1:-}" != dump ] && [ "${1:-}" != check ]; then
  echo "usage: api.sh dump|check" >&2
  exit 2
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
target="$(uname -m)-apple-ios12.0-simulator"

find PeekKit/Classes -name '*.swift' -print0 | xargs -0 xcrun swiftc -emit-module -module-name PeekKit -swift-version 5 \
  -sdk "$sdk" -target "$target" -emit-module-path "$work/PeekKit.swiftmodule"
xcrun swift-api-digester -dump-sdk -module PeekKit -I "$work" -sdk "$sdk" -target "$target" -o "$work/api.json"

# The digester has no async field; only the mangled name has it. A function is async when "async" follows its own parameter list.
jq -r '.. | objects | select(.declKind == "Func" or .declKind == "Constructor") | .mangledName // empty' "$work/api.json" > "$work/mangled.txt"
xcrun swift-demangle < "$work/mangled.txt" > "$work/demangled.txt"
async=$(paste "$work/mangled.txt" "$work/demangled.txt" | jq -R -n '
  def after_parameters:
    . as $s | (index("(") // length) as $open
    | (reduce range($open; length) as $i ({depth: 0, end: null};
        if .end != null then .
        elif $s[$i:$i + 1] == "(" then .depth += 1
        elif $s[$i:$i + 1] == ")" then .depth -= 1 | (if .depth == 0 then .end = $i else . end)
        else . end)).end as $end
    | if $end == null then "" else $s[$end + 1:] end;
  [inputs | split("\t") | select(.[1] | after_parameters | startswith(" async")) | .[0]]')

jq -r --argjson async "$async" '
  def types: [.children[]? | select(.kind | startswith("Type")) | (if .paramValueOwnership == "InOut" then "inout " else "" end) + .printedName + (if .hasDefaultArg then " = default" else "" end)];
  def generics: if .genericSig and (.protocolReq | not) then .genericSig else "" end;
  def is_async: (.mangledName // "") as $m | any($async[]; . == $m);
  def keyword:
    if .declKind == "Func" then "func"
    elif .declKind == "Constructor" then ""
    elif .declKind == "EnumElement" then "case"
    elif .declKind == "Var" then (if .isLet then "let" else "var" end)
    else .declKind | ascii_downcase end;
  def signature($name):
    types as $t
    | if .declKind == "Func" or .declKind == "Constructor" or .declKind == "Subscript" then
        (.printedName | capture("\\((?<l>.*)\\)$").l | split(":")[:-1]) as $labels
        | "\($name | sub("\\(.*"; ""))\(generics)(\([range($labels | length) as $i | "\($labels[$i]): \($t[$i + 1])"] | join(", ")))"
          + (if is_async then " async" else "" end)
          + (if .throwing then " throws" else "" end)
          + (if .declKind == "Constructor" or $t[0] == "()" then "" else " -> \($t[0])" end)
      elif .declKind == "TypeAlias" then "\($name)\(generics) = \($t[0])"
      elif .declKind == "EnumElement" then $name + (if $t[0] | test("^\\(.*\\) -> \\(.+\\) -> ") then $t[0] | capture("-> (?<p>\\(.+\\)) -> ").p else "" end)
      elif .declKind == "Var" then "\($name): \($t[0]) { \([.accessors[]?.accessorKind | select(. == "get" or . == "set")] | join(" ")) }"
      elif .superclassNames then "\($name)\(generics): \(.superclassNames | join(", "))"
      else "\($name)\(generics)" end;
  def decls($path):
    .children[]?
    | select(.declKind != null and .declKind != "Import" and .declKind != "Accessor")
    | ($path + .printedName) as $name
    | [$name, ([
        (if .isOpen then "open" else empty end),
        (if .declKind == "Class" and ((.declAttributes // []) | index("Final")) then "final" else empty end),
        (if .static then "static" else empty end),
        (if .funcSelfKind == "Mutating" then "mutating" else empty end),
        keyword,
        signature($name)
      ] | map(select(. != "")) | join(" "))],
      # One line per conformance, so adding one reads as new API and removing one as a removal. Copyable, Escapable and
      # BitwiseCopyable are compiler markers that differ between Xcode versions.
      (.conformances[]?.printedName | select(IN("Copyable", "Escapable", "BitwiseCopyable") | not) | [$name, "conformance \($name): \(.)"]),
      decls($name + ".");
  .ABIRoot | [decls("")] | sort | .[][1]
' "$work/api.json" > "$work/PeekKit.api"

if [ "$1" = dump ]; then
  mkdir -p "$(dirname "$api")"
  cp "$work/PeekKit.api" "$api"
  echo "Wrote $api"
elif ! diff -u "$api" "$work/PeekKit.api"; then
  echo "The public API differs from $api (- file, + code). If the change is intended, run bash scripts/api.sh dump and commit $api." >&2
  exit 1
else
  echo "The public API matches $api."
fi
