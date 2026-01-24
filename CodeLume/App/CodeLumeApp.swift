import SwiftUI

@main
struct CodeLumeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        MenuBarExtra("CodeLume", image: "CodeLumeIcon") {
            MenuBarView()
        }
        
        WindowGroup("CodeLume", id: "home") {
            HomeView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 600)
        .windowResizability(.contentSize)
    }
}
