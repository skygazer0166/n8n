# Socialite (personal build)

An iPhone app that opens Instagram and YouTube with the addictive parts removed:

- **Instagram:** Reels tab, reels in the feed, Explore and profiles, and the `/reels` pages.
- **YouTube:** the Shorts shelf, the Shorts tab, and the `/shorts` pages. A shared Shorts link plays as a normal video.

Messages, normal posts and normal videos keep working. Each site has an on/off switch in Settings.

## How it works (plain English)

iOS does not let one app change another app, so this app is a small browser. It opens the
real websites and, on every page, runs a few lines of code that hide the Reels and Shorts
parts. It also refuses to open any Reels or Shorts page. All of that logic is in
`Socialite/Rules.swift`.

## Run it on your iPhone (one time, about 15 minutes)

You need a Mac with Xcode (free from the Mac App Store).

1. Open Xcode, then **File > New > Project > iOS > App**. Click Next.
2. Product Name: `Socialite`. Interface: **SwiftUI**. Language: **Swift**. Click Next and save it anywhere.
3. In the left sidebar, delete the two files Xcode made (`SocialiteApp.swift` and `ContentView.swift`). Choose **Move to Trash**.
4. Drag the 4 files from this repo's `Socialite/Socialite/` folder into the same sidebar spot:
   `SocialiteApp.swift`, `SiteController.swift`, `Rules.swift`, `SettingsView.swift`.
   Tick **Copy items if needed** and make sure the **Socialite** target is ticked.
5. Click the blue project icon at the top of the sidebar, then **Signing & Capabilities**.
   Tick **Automatically manage signing** and choose your Apple ID under Team.
   (Add it in Xcode > Settings > Accounts if it is not listed.)
6. Under **General > Minimum Deployments**, set iOS to **17.0**.
7. Plug in your iPhone. On the phone, enable **Settings > Privacy & Security > Developer Mode** and restart.
8. Pick your iPhone at the top of Xcode and press the **Play** button.
9. First launch only: on the phone, go to **Settings > General > VPN & Device Management**, tap your Apple ID, and tap **Trust**.

To try it without a phone, pick any iPhone simulator at step 8.

A free Apple ID installs the app for 7 days. After that, press Play again in Xcode to
renew it. The paid developer account ($99/year) removes that limit and is only needed if you ever want TestFlight or the App Store.

## When something slips through

Instagram and YouTube change their pages from time to time. If a Reel or Short shows up
again, send me a screenshot and I will update `Rules.swift`.

## Known limits

- No push notifications (web apps cannot receive them like the official apps).
- Delete the official Instagram and YouTube apps, or limit them with Screen Time, or you may still use those instead.
- Reels sent to you in Instagram direct messages are left alone on purpose.
- Not tested on a device yet: it was written without Xcode, so expect to send me any build errors.
