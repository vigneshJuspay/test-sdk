# PeekKit

PeekKit opens a random web page. You press a button, a page you did not ask for slides up, you read three sentences, you close it. That is the whole product.

## Installation

### Swift Package Manager

In Xcode, choose **File > Add Package Dependencies**, paste this repository's URL and add the `PeekKit` library.

### CocoaPods

```ruby
pod 'PeekKit'
```

See [Versioning](docs/versioning.md).

## Usage

```swift
let peeker = Peeker()
peeker.peek(from: self) { status in
    print("peek:", status)
}
```

## FAQ

**Which page will I get?** Nobody knows. That is the point.

**Can I choose the page?** No. Choosing would make it a browser.

**Is it useful?** It is mostly here so a release pipeline has something to build.

## Signed XCFramework

Every GitHub release also attaches a signed `PeekKit.xcframework.zip`, its SHA-256 checksum and a CycloneDX SBOM. See [Verify a release](docs/verify-release.md) for how to check them.
