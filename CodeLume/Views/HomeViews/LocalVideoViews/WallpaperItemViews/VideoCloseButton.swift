import SwiftUI

struct VideoCloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.black, .red)
                .font(.system(size: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(8)
    }
}

#Preview {
    VideoCloseButton(action: {})
        .frame(width: 50, height: 50)
}
