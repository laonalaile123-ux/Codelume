import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    let windowController = WindowController()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !isAppAlreadyRunning() {
            let hideDockIcon = UserDefaults.standard.object(forKey: "hideDockIcon") as? Bool ?? false
            let _ = DatabaseManger.shared
            setDockIconVisibility(hideDockIcon)
        }
    }
    
    private func isAppAlreadyRunning() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier!
        let runningApps = NSWorkspace.shared.runningApplications
        
        let otherInstances = runningApps.filter {
            $0.bundleIdentifier == bundleID
            && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }
        
        return !otherInstances.isEmpty
    }
}
