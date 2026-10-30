import UIKit
import WebKit

class PeekWebView: UIViewController, WKNavigationDelegate {
    private let page: URL
    private let closeTitle: String
    private let onStatus: PeekHandler

    init(page: URL, closeTitle: String, onStatus: @escaping PeekHandler) {
        self.page = page
        self.closeTitle = closeTitle
        self.onStatus = onStatus
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func loadView() {
        let webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
        webView.load(URLRequest(url: page))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: closeTitle, style: .done, target: self, action: #selector(close))
    }

    @objc private func close() {
        dismiss(animated: true) {
            self.onStatus("closed")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onStatus("loaded \(page.absoluteString)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onStatus("failed: \(error.localizedDescription)")
    }
}
