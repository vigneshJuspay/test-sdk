set -euo pipefail

#   bash scripts/sbom.sh <version> > PeekKit.cdx.json

if [ $# -ne 1 ]; then
  echo "usage: sbom.sh <version>" >&2
  exit 2
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Resolved in a copy, so a Package.resolved or .build never lands in the repo.
mkdir -p "$work/package/Example"
cp -R Package.swift PeekKit "$work/package/"
cp -R Example/Tests "$work/package/Example/"
swift package --package-path "$work/package" --scratch-path "$work/build" show-dependencies --format json > "$work/graph.json"

jq --arg version "$1" --arg serial "urn:uuid:$(uuidgen | tr '[:upper:]' '[:lower:]')" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  def nodes: ., (.dependencies[] | nodes);
  def purl: "pkg:swift/" + (.url | sub("^[a-z]+://"; "") | sub("\\.git$"; "")) + "@" + .version;
  ([.dependencies[] | nodes] | unique_by(.identity)) as $packages
  | {
      bomFormat: "CycloneDX",
      specVersion: "1.5",
      serialNumber: $serial,
      version: 1,
      metadata: {
        timestamp: $timestamp,
        component: {
          type: "library",
          "bom-ref": "PeekKit",
          name: "PeekKit",
          version: $version,
          purl: ("pkg:swift/github.com/example/test-sdk@" + $version),
          licenses: [{ license: { id: "MIT" } }]
        }
      },
      components: [$packages[] | { type: "library", "bom-ref": .identity, name: .name, version: .version, purl: purl }],
      dependencies: (
        [{ ref: "PeekKit", dependsOn: [.dependencies[].identity] }]
        + [$packages[] | { ref: .identity, dependsOn: [.dependencies[].identity] }]
      )
    }' "$work/graph.json"
