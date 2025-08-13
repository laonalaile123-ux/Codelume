import AppKit

extension NSScreen {
    var identifier: String {
        return self.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? String ?? "unknown"
    }
}
