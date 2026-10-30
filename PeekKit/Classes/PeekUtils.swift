import Foundation

public func isSecurePage(_ url: URL) -> Bool {
    return url.scheme?.lowercased() == "https"
}

func randomPage(from pages: [URL]) -> URL? {
    return pages.filter(isSecurePage).randomElement()
}
