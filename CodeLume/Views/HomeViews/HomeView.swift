import SwiftUI

struct HomeView: View {
    @AppStorage(ENABLE_BACKGROUND_EFFECTS) private var enableBackgroundEffects: Bool = true
    @StateObject private var hubFilters = WallpaperHubFilterModel()

    var body: some View {
        ZStack {
            if enableBackgroundEffects {
                GlowOrbs()
                AuroraView()
            }
            NavigationSplitView {
                VStack {
                    List {
                        NavigationLink(destination: ScreenManagerView()
                            .navigationTitle("")) {
                                Label("ScreenManager", systemImage: "display.2")
                            }
                        NavigationLink(destination: LocalWallpapersView()
                            .navigationTitle("")) {
                                Label("LocalWallpaper", systemImage: "photo.on.rectangle")
                            }
                        NavigationLink(destination: WallpaperHubView()
                            .environmentObject(hubFilters)
                            .navigationTitle("")) {
                                Label("Wallpaper Hub", systemImage: "icloud.and.arrow.down")
                            }
                        NavigationLink(destination: ScreenSaverView()
                            .navigationTitle("")) {
                                Label("Screen Saver", systemImage: "sparkles")
                            }
                        NavigationLink(destination: SettingsView()
                            .navigationTitle("")) {
                                Label("Preferences", systemImage: "gear")
                            }
                        NavigationLink(destination: TopUpCreditsView()
                            .navigationTitle("")) {
                                Label("Top up", systemImage: "creditcard")
                            }
                        NavigationLink(destination: AboutView()
                            .navigationTitle("")) {
                                Label("About", systemImage: "info.circle")
                            }
                    }
                    .listStyle(.sidebar)

                    Spacer()

                    // if hubFilters.isWallpaperHubDetailVisible {
                    //     ScrollView {
                    //         WallpaperHubSidebarFiltersView(filters: hubFilters)
                    //     }
                    // }

                    UserAuthView()

                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text(String(format: String(localized: "Version %@"), version))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(5)
                    }
                }
                .navigationSplitViewColumnWidth(min: 220, ideal: 220, max: 220)
            } detail: {
                LocalWallpapersView()
                    .navigationTitle("")
            }
        }
    }
}

#Preview {
    HomeView()
}
