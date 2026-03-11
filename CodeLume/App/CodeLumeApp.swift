import SwiftUI

@main
struct CodelumeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        MenuBarExtra("Codelume", image: "CodelumeIcon") {
            MenuBarView()
        }
        
        WindowGroup("Codelume", id: "home") {
            HomeView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}
