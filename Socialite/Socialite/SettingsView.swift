import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    @AppStorage("block.instagram") private var blockInstagram = true
    @AppStorage("block.youtube") private var blockYouTube = true
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Block short videos"),
                    footer: Text("Hides Reels, the Reels tab and reels in your feed. Messages and normal posts still work.")
                ) {
                    Toggle("Instagram Reels", isOn: $blockInstagram)
                        .onChange(of: blockInstagram) { model.controllers[.instagram]?.installRules() }
                }
                Section(
                    footer: Text("Hides the Shorts shelf and Shorts tab. Normal videos still work, and a shared Shorts link plays as a normal video.")
                ) {
                    Toggle("YouTube Shorts", isOn: $blockYouTube)
                        .onChange(of: blockYouTube) { model.controllers[.youtube]?.installRules() }
                }
                Section(footer: Text("Logs you out of Instagram and YouTube inside this app.")) {
                    Button("Log out of everything", role: .destructive) {
                        showClearConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Log out of Instagram and YouTube?", isPresented: $showClearConfirm) {
                Button("Log out", role: .destructive) {
                    WKWebsiteDataStore.default().removeData(
                        ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                        modifiedSince: .distantPast
                    ) {
                        model.controllers.values.forEach { $0.installRules() }
                    }
                }
            }
        }
    }
}
