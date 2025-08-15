import AppKit

extension NSApplicationDelegate {
    var windowController: WindowController? {
        (self as? AppDelegate)?.windowController
    }
}
