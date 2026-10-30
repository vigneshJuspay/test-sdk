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

## FAQ

**Which page will I get?** Nobody knows. That is the point.

**Can I choose the page?** No. Choosing would make it a browser.

**Is it useful?** It is mostly here so a release pipeline has something to build.
