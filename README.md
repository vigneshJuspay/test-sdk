# PeekKit

PeekKit opens a random web page. You press a button, a page you did not ask for slides up, you read three sentences, you close it. That is the whole product.

## Installation

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
