import Cocoa
import SwiftUI
import SwiftyBeaver

class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var windowController: WindowController = WindowController()
    private var welcomeWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        let _ = SwiftyBeaverLog.shared
        let _ = UserDefaultsManager.shared
        let _ = DatabaseManger.shared
        let _ = ScreenManager.shared
        let _ = windowController
        Logger.info("Codelume application started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.info("Codelume application terminated")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let theme = UserDefaultsManager.shared.getTheme()
        switch theme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
        
        let showWelcomeView = UserDefaultsManager.shared.getWelcomeStatus()
        if showWelcomeView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showWelcomeWindow()
            }
        }
    }
    
    private func showWelcomeWindow() {
        let welcomeView = WelcomeView()
        let hostingController = NSHostingController(rootView: welcomeView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 300),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.isOpaque = false
        window.backgroundColor = .clear
        
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 20.0
            contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        welcomeWindow = window
    }
}
