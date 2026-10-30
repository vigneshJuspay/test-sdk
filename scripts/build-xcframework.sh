set -euo pipefail

#   bash scripts/build-xcframework.sh <version> [output-dir]

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "usage: build-xcframework.sh <version> [output-dir]" >&2
  exit 2
fi
version=$1
out=${2:-build/xcframework}
identity=${APPLE_DIST_IDENTITY:-}
# Info.plist versions must be plain numbers (App Store validation rejects an embedded framework with "1.2.0-beta.1").
plist_version=${version%%-*}

fail() {
  echo "✗ $1" >&2
  exit 1
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The library product is automatic, and archiving an automatic product yields a bare object file. A copy of the
# package declares it dynamic, so the archive is a framework; the committed Package.swift, and what SPM users get,
# stay as they are.
mkdir -p "$work/package/Example"
cp -R Package.swift PeekKit "$work/package/"
cp -R Example/Tests "$work/package/Example/"
sed -i '' 's/\.library(name: "PeekKit", targets: \["PeekKit"\])/.library(name: "PeekKit", type: .dynamic, targets: ["PeekKit"])/' "$work/package/Package.swift"
grep -q 'type: .dynamic' "$work/package/Package.swift" || fail "Could not make the PeekKit product dynamic: has its declaration in Package.swift changed?"
echo 'import PeekKit' > "$work/import.swift"

args=()
for slice in iphoneos iphonesimulator; do
  if [ "$slice" = iphoneos ]; then destination="generic/platform=iOS"; else destination="generic/platform=iOS Simulator"; fi
  archive="$work/$slice.xcarchive"
  echo "Archiving for $destination"
  (cd "$work/package" && xcodebuild archive -scheme PeekKit -destination "$destination" -archivePath "$archive" \
    -derivedDataPath "$work/derived-$slice" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES CODE_SIGNING_ALLOWED=NO) \
    > "$work/$slice.log" 2>&1 || { tail -40 "$work/$slice.log" >&2; fail "xcodebuild archive failed for $destination"; }

  framework=$(find "$archive/Products" -name PeekKit.framework -type d | head -1)
  module=$(find "$work/derived-$slice/Build/Intermediates.noindex/ArchiveIntermediates" -path '*/BuildProductsPath/*/PeekKit.swiftmodule' -type d | head -1)
  [ -n "$framework" ] || fail "The $slice archive has no PeekKit.framework"
  [ -n "$module" ] || fail "The $slice build produced no PeekKit.swiftmodule"

  # Xcode leaves the module interface and the privacy manifest out of an SPM framework; an XCFramework needs both.
  mkdir -p "$framework/Modules"
  cp -R "$module" "$framework/Modules/"
  cp PeekKit/Resources/PrivacyInfo.xcprivacy "$framework/"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.example.PeekKit" \
    -c "Set :CFBundleShortVersionString $plist_version" -c "Set :CFBundleVersion $plist_version" "$framework/Info.plist"

  ls "$framework/Modules/PeekKit.swiftmodule/"*.swiftinterface > /dev/null 2>&1 || fail "The $slice slice has no .swiftinterface"
  # Only Apple's frameworks and system libraries: anything else would be third-party code shipping inside the SDK.
  others=$(otool -L "$framework/PeekKit" | grep -E '^[[:space:]]' | awk '{print $1}' \
    | grep -vE '^(/System/Library/Frameworks/|/usr/lib/|@rpath/PeekKit\.framework/PeekKit$)' || true)
  [ -z "$others" ] || fail "The $slice binary links libraries outside the system: $(echo "$others" | tr '\n' ' ')"
  # Compiled from the .swiftinterface alone, as an app on a newer Xcode will.
  minimum=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$framework/Info.plist")
  if [ "$slice" = iphoneos ]; then target="arm64-apple-ios$minimum"; else target="arm64-apple-ios$minimum-simulator"; fi
  xcrun --sdk "$slice" swiftc -typecheck -target "$target" -F "$(dirname "$framework")" "$work/import.swift" \
    || fail "An app could not import PeekKit from the $slice slice"

  args+=(-framework "$framework")
  dsym="$archive/dSYMs/PeekKit.framework.dSYM"
  if [ -d "$dsym" ]; then args+=(-debug-symbols "$dsym"); fi
done

rm -rf "$out"
mkdir -p "$out"
xcodebuild -create-xcframework "${args[@]}" -output "$out/PeekKit.xcframework" > /dev/null

if [ -n "$identity" ]; then
  if [ "$identity" = "-" ]; then timestamp=--timestamp=none; else timestamp=--timestamp; fi
  codesign "$timestamp" --sign "$identity" "$out/PeekKit.xcframework"
  codesign --verify --strict --verbose=2 "$out/PeekKit.xcframework"
else
  echo "Not signed: set APPLE_DIST_IDENTITY to sign the XCFramework."
fi

(cd "$out" && ditto -c -k --keepParent PeekKit.xcframework PeekKit.xcframework.zip \
  && shasum -a 256 PeekKit.xcframework.zip > PeekKit.xcframework.zip.sha256)
echo "Wrote $out/PeekKit.xcframework.zip ($version, minimum iOS $minimum) and its .sha256"
