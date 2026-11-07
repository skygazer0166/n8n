import Foundation

/// The two websites the app can show.
enum Site: String, CaseIterable, Identifiable {
    case instagram
    case youtube

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        }
    }

    var systemImage: String {
        switch self {
        case .instagram: return "camera"
        case .youtube: return "play.rectangle"
        }
    }

    var homeURL: URL {
        switch self {
        case .instagram: return URL(string: "https://www.instagram.com/")!
        case .youtube: return URL(string: "https://m.youtube.com/")!
        }
    }

    /// UserDefaults key for the "block short videos" switch.
    var blockKey: String { "block.\(rawValue)" }

    /// Links to these hosts open inside the app; anything else opens in Safari.
    var inAppHostSuffixes: [String] {
        switch self {
        case .instagram: return ["instagram.com", "facebook.com", "fb.com"]
        case .youtube: return ["youtube.com", "youtu.be", "google.com"]
        }
    }

    var isBlockingEnabled: Bool {
        (UserDefaults.standard.object(forKey: blockKey) as? Bool) ?? true
    }
}

/// All the "remove the addictive stuff" logic lives in this file.
/// If Instagram or YouTube change their pages and something slips through,
/// this is the only file that needs updating.
enum Rules {

    // MARK: - Native (Swift) side: stop navigating to short-video pages

    /// If the URL is a Reels/Shorts page, returns where to go instead. Otherwise nil.
    static func replacement(for url: URL, site: Site) -> URL? {
        let path = url.path
        switch site {
        case .instagram:
            // /reels/, /reel/<id>, /<user>/reels/
            if path.range(of: #"^/(reels?)(/|$)"#, options: .regularExpression) != nil
                || path.range(of: #"^/[^/]+/reels/?$"#, options: .regularExpression) != nil {
                return site.homeURL
            }
        case .youtube:
            if path.hasPrefix("/shorts/") {
                // A shared Short link plays as a normal video instead of the Shorts feed.
                let id = path.dropFirst("/shorts/".count).split(separator: "/").first.map(String.init) ?? ""
                if !id.isEmpty, let u = URL(string: "https://m.youtube.com/watch?v=\(id)") { return u }
                return site.homeURL
            }
            if path == "/shorts" { return site.homeURL }
        }
        return nil
    }

    static func script(for site: Site) -> String {
        switch site {
        case .instagram: return instagramJS
        case .youtube: return youtubeJS
        }
    }

    // MARK: - Page (JavaScript) side: hide Reels/Shorts inside pages

    static let instagramJS = #"""
    (function () {
      if (window.__socialiteInstalled) return;
      window.__socialiteInstalled = true;

      function hide(el) {
        if (el && el.style && el.style.display !== 'none') {
          el.style.setProperty('display', 'none', 'important');
        }
      }

      // Hide a link; also hide its wrapper if the wrapper holds nothing else
      // (this removes the empty tab-bar slot).
      function hideLink(a) {
        hide(a);
        var p = a.parentElement;
        if (p && p.children.length === 1) hide(p);
      }

      function guard() {
        var p = location.pathname;
        if (/^\/reels?(\/|$)/.test(p) || /^\/[^\/]+\/reels\/?$/.test(p)) {
          location.replace('/');
        }
      }

      function sweep() {
        guard();
        // "Reels" tab in the navigation bar.
        document.querySelectorAll('a[href="/reels/"], a[href="/reels"]').forEach(hideLink);

        // Leave direct messages alone so reels sent by friends do not get mangled.
        if (location.pathname.indexOf('/direct') === 0) return;

        // Reels shown in the feed, Explore and profiles.
        document.querySelectorAll('a[href*="/reel/"], a[href*="/reels/"]').forEach(function (a) {
          var post = a.closest('article');
          if (post) hide(post); else hideLink(a);
        });
        // Reels tab on profile pages.
        document.querySelectorAll('a[href$="/reels/"]').forEach(hideLink);
      }

      // Instagram changes pages without reloading, so watch for that.
      ['pushState', 'replaceState'].forEach(function (name) {
        var orig = history[name];
        history[name] = function () {
          var r = orig.apply(this, arguments);
          setTimeout(sweep, 0);
          return r;
        };
      });
      window.addEventListener('popstate', sweep);

      var scheduled = false;
      new MutationObserver(function () {
        if (scheduled) return;
        scheduled = true;
        requestAnimationFrame(function () { scheduled = false; sweep(); });
      }).observe(document.documentElement, { childList: true, subtree: true });

      setInterval(sweep, 800);
      sweep();
    })();
    """#

    static let youtubeJS = #"""
    (function () {
      if (window.__socialiteInstalled) return;
      window.__socialiteInstalled = true;

      var css = [
        'ytm-reel-shelf-renderer',
        'ytd-reel-shelf-renderer',
        'ytm-shorts-lockup-view-model',
        'ytm-shorts-lockup-view-model-v2',
        'ytm-reel-item-renderer',
        'ytm-pivot-bar-item-renderer:has(a[href^="/shorts"])',
        'ytm-pivot-bar-item-renderer:has([aria-label="Shorts"])'
      ].join(',') + ' { display: none !important; }';
      var style = document.createElement('style');
      style.textContent = css;
      document.documentElement.appendChild(style);

      var ITEMS = [
        'ytm-rich-item-renderer',
        'ytm-video-with-context-renderer',
        'ytm-compact-video-renderer',
        'ytm-reel-shelf-renderer',
        'yt-lockup-view-model',
        'ytm-pivot-bar-item-renderer',
        'grid-shelf-view-model'
      ].join(',');

      function hide(el) {
        if (el && el.style && el.style.display !== 'none') {
          el.style.setProperty('display', 'none', 'important');
        }
      }

      function guard() {
        var p = location.pathname;
        var m = p.match(/^\/shorts\/([^\/?#]+)/);
        if (m) { location.replace('/watch?v=' + m[1]); return; }
        if (p === '/shorts') location.replace('/');
      }

      function sweep() {
        guard();
        document.querySelectorAll('a[href^="/shorts"], a[href*="youtube.com/shorts"]').forEach(function (a) {
          hide(a.closest(ITEMS) || a);
        });
      }

      ['pushState', 'replaceState'].forEach(function (name) {
        var orig = history[name];
        history[name] = function () {
          var r = orig.apply(this, arguments);
          setTimeout(sweep, 0);
          return r;
        };
      });
      window.addEventListener('popstate', sweep);

      var scheduled = false;
      new MutationObserver(function () {
        if (scheduled) return;
        scheduled = true;
        requestAnimationFrame(function () { scheduled = false; sweep(); });
      }).observe(document.documentElement, { childList: true, subtree: true });

      setInterval(sweep, 800);
      sweep();
    })();
    """#
}
