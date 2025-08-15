import SwiftUI

struct VideoNameLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .foregroundColor(.black)
            .truncationMode(.middle)
            .lineLimit(1)
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(1.0))
            )
    }
}

#Preview {
    VideoNameLabel(text: "codelume_0.mp4")
        .frame(width: 300, height: 50)
}
