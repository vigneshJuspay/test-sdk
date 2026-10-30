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

`onStatus` is called with a short status string: `loaded <url>` when the page finishes, `failed: <reason>` when it does not, and `closed` when the person closes the sheet.

### Close it yourself

You do not need to. The sheet has its own close button, and PeekKit keeps no state between peeks.

## FAQ

**Which page will I get?** Nobody knows. That is the point.

**Can I choose the page?** No. Choosing would make it a browser.

**Is it useful?** It is mostly here so a release pipeline has something to build.
