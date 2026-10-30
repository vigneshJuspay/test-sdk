# Verify a release

Every [GitHub release](https://github.com/example/test-sdk/releases) of PeekKit attaches three files:

| File | What it is |
| --- | --- |
| `PeekKit.xcframework.zip` | The SDK compiled for iPhone and the simulator, signed with the publisher's Apple Distribution certificate |
| `PeekKit.xcframework.zip.sha256` | The zip's SHA-256 checksum |
| `PeekKit.cdx.json` | A [CycloneDX](https://cyclonedx.org) 1.5 SBOM: the packages PeekKit depends on |

Swift Package Manager and CocoaPods build the SDK from source and do not use these files.

## Check the download

```bash
shasum -a 256 -c PeekKit.xcframework.zip.sha256
```

It prints `PeekKit.xcframework.zip: OK`.

## Check the signature

```bash
ditto -x -k PeekKit.xcframework.zip .
codesign --verify --strict --verbose=2 PeekKit.xcframework
codesign -dv --verbose=4 PeekKit.xcframework 2>&1 | grep -E 'Authority=Apple Distribution|TeamIdentifier'
```

The first `codesign` prints `valid on disk` and `satisfies its Designated Requirement`. The second must show `TeamIdentifier=<TEAM_ID>`, the publisher's Apple Team ID. Any other Team ID, or `code object is not signed at all`, means the file is not the published one.

## Check the SBOM

```bash
jq '.components' PeekKit.cdx.json
```

PeekKit uses only Apple's frameworks, so the list is empty: `[]`.

## Add the XCFramework to your app

In Xcode, select your app target, open **General > Frameworks, Libraries, and Embedded Content**, click **+**, choose **Add Other… > Add Files…** and pick `PeekKit.xcframework`. Set it to **Embed & Sign**.

The XCFramework includes the SDK's privacy manifest (`PrivacyInfo.xcprivacy`). Xcode 15 and later show who signed it in the File inspector, and warn when a later version is signed by someone else.
