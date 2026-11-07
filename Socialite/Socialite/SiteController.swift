import SwiftUI
import WebKit

/// Owns one website (Instagram or YouTube): its web view, login session and blocking rules.
final class SiteController: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let site: Site
    let webView: WKWebView

    init(site: Site) {
        self.site = site

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // The default store keeps you logged in between launches.
        config.websiteDataStore = .default()

        let view = WKWebView(frame: .zero, configuration: config)
        view.allowsBackForwardNavigationGestures = true
        self.webView = view

        super.init()

        view.navigationDelegate = self
        view.uiDelegate = self

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        view.scrollView.refreshControl = refresh

        installRules()
        view.load(URLRequest(url: site.homeURL))
    }

    /// (Re)installs the hiding script according to the current setting, then reloads.
    func installRules() {
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        if site.isBlockingEnabled {
            let script = WKUserScript(
                source: Rules.script(for: site),
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            controller.addUserScript(script)
        }
        webView.reload()
    }

    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }

    // MARK: WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Never open Reels / Shorts pages.
        if site.isBlockingEnabled, navigationAction.targetFrame?.isMainFrame ?? true,
           let replacement = Rules.replacement(for: url, site: site) {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: replacement))
            return
        }

        // Tapped links to other websites open in Safari.
        if navigationAction.navigationType == .linkActivated,
           let host = url.host?.lowercased(),
           !site.inAppHostSuffixes.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: WKUIDelegate

    /// Links that want a new window just load in the same view.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

/// Holds both sites so they stay alive (and logged in) while you switch tabs.
final class AppModel: ObservableObject {
    let controllers: [Site: SiteController] = Dictionary(
        uniqueKeysWithValues: Site.allCases.map { ($0, SiteController(site: $0)) }
    )
}

/// Shows a SiteController's web view inside SwiftUI.
struct SiteWebView: UIViewRepresentable {
    let controller: SiteController

    func makeUIView(context: Context) -> WKWebView { controller.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
