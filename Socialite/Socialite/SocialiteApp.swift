import SwiftUI

@main
struct SocialiteApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        TabView {
            ForEach(Site.allCases) { site in
                if let controller = model.controllers[site] {
                    SiteWebView(controller: controller)
                        .ignoresSafeArea(edges: .bottom)
                        .tabItem { Label(site.title, systemImage: site.systemImage) }
                }
            }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
