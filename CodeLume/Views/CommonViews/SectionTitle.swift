import SwiftUI

struct SectionTitle: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 2)
    }
}

#Preview {
    SectionTitle(title: "Codelume")
}


