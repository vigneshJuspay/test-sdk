# PeekKit

PeekKit opens a random web page. You press a button, a page you did not ask for slides up, you read three sentences, you close it. That is the whole product.

## Installation

Add PeekKit with Swift Package Manager or CocoaPods. The Swift Package Manager route includes the privacy manifest (`PrivacyInfo.xcprivacy`).

### Swift Package Manager

In Xcode, choose **File > Add Package Dependencies**, enter this repository URL, choose **Up to Next Major Version** and add the `PeekKit` product to your app target.

If your project is built from a `Package.swift`, add the package and depend on its `PeekKit` product:

```swift
dependencies: [
    .package(url: "https://github.com/example/test-sdk.git", from: "<VERSION>")
],
targets: [
    .target(
        name: "<YOUR_TARGET>",
        dependencies: [.product(name: "PeekKit", package: "test-sdk")]
    )
]
```

### CocoaPods

PeekKit is available through CocoaPods:

```ruby
pod 'PeekKit'
```

See [Versioning](docs/versioning.md).

What changed in each version is in [CHANGELOG.md](CHANGELOG.md).

### Signed XCFramework

Every GitHub release also attaches a signed `PeekKit.xcframework.zip`, its SHA-256 checksum and a CycloneDX SBOM. See [Verify a release](docs/verify-release.md) for how to check them.

## Usage

```swift
let peeker = Peeker()
peeker.peek(from: self) { status in
    print("peek:", status)
}
```

## Guide

### Peek at a page

Create one `Peeker` per screen and call `peek(from:onStatus:)` from a button. The page opens in a sheet with a close button.

### What your app receives

`onStatus` is called with a short status string: `loaded <url>` when the page finishes, `failed: <reason>` when it does not, and `closed` when the person closes the sheet. When a failure has a code, it is listed in [Error codes](docs/error-codes.md).

### Close it yourself

You do not need to. The sheet has its own close button, and PeekKit keeps no state between peeks.

### Error codes

The error codes PeekKit reports are listed in [Error codes](docs/error-codes.md).

## FAQ

**Which page will I get?** Nobody knows. That is the point.

**Can I choose the page?** No. Choosing would make it a browser.

**Is it useful?** It is mostly here so a release pipeline has something to build.
