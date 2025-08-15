import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
            
            Text("CodeLume")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .center, spacing: 10) {
                Text("A dynamic wallpaper software dedicated to the macOS platform.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("If you have any suggestions or comments during use, please contact the developer through the link below.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            Button {
                NSWorkspace.shared.open(URL(string: "https://www.codelume.cn")!)
            } label: {
                Text("Visit the official website.")
            }
            
            
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String{
                Text("Version \(version)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("© 2025 CodeLume. All rights reserved.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 500, height: 400)
    }
}

#Preview {
    AboutView()
}
