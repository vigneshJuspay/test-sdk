import Foundation
import UIKit

public typealias PeekHandler = (_ status: String) -> Void

public class Peeker: NSObject {
    private let config = PeekConfig.standard

    public func peek(from presenter: UIViewController, onStatus: @escaping PeekHandler) {
        guard let page = randomPage(from: config.pages) else {
            onStatus("no page to peek at")
            return
        }
        let webView = PeekWebView(page: page, closeTitle: config.closeTitle, onStatus: onStatus)
        DispatchQueue.main.async {
            presenter.present(UINavigationController(rootViewController: webView), animated: true)
        }
    }
}
