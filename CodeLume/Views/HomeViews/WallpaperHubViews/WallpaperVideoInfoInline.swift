import SwiftUI

struct WallpaperVideoInfoInline: View {
    let info: WallpaperVideoInfoTable?
    let isLoading: Bool
    
    var body: some View {
        Group {
            if let info {
                Text("\(info.resolutionText) | \(formattedSize(info.sizeMB)) | \(formattedDuration(info.duration)) | \(info.loop ? "Loop" : "No Loop") | \(info.isEncrypted ? "Encrypted" : "Not Encrypted")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formattedSize(_ sizeMB: Decimal) -> String {
        let value = max(NSDecimalNumber(decimal: sizeMB).doubleValue, 0)
        return String(format: "%.2f MB", value)
    }
    
    private func formattedDuration(_ seconds: Int) -> String {
        let total = max(seconds, 0)
        let hour = total / 3600
        let minute = (total % 3600) / 60
        let second = total % 60
        
        if hour > 0 {
            return String(format: "%02d:%02d:%02d", hour, minute, second)
        }
        
        return String(format: "%02d:%02d", minute, second)
    }
}
