import SwiftUI

@main
struct CodeLumeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        MenuBarExtra("CodeLume", image: "CodeLumeIcon") {
            MenuBarView()
                .onAppear {
                    let theme = UserDefaultsManager.shared.getTheme()
                    switch theme {
                    case .light:
                        NSApp.appearance = NSAppearance(named: .aqua)
                    case .dark:
                        NSApp.appearance = NSAppearance(named: .darkAqua)
                    default:
                        NSApp.appearance = nil
                    }
                }
        }
        
        WindowGroup("CodeLume", id: "home") {
            HomeView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 600)
        .windowResizability(.contentSize)
    }
}
