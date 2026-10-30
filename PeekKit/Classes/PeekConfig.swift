import Foundation

struct PeekConfig {
    let pages: [URL]
    let closeTitle: String

    static let standard = PeekConfig(
        pages: PeekConstants.pages.compactMap(URL.init(string:)),
        closeTitle: PeekConstants.closeTitle
    )
}
