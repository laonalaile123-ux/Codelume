import SwiftUI

struct WallpaperTypeLabel: View {
    let type: String

    var body: some View {
        Text(type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "unknown" : type.lowercased())
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
    }
}
