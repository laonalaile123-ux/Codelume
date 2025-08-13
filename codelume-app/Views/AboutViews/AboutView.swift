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
            
            VStack(alignment: .leading, spacing: 10) {
                Text("CodeLume is an all-in-one desktop enhancement and productivity tool, featuring:")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("• Dynamic Wallpaper: Custom video wallpapers for personalized desktops")
                        .fixedSize(horizontal: false, vertical: true)
                    Text("• Other utilities: More features coming soon...")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
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
            
            Text("© 2025 guangziyu. All rights reserved.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

#Preview {
    AboutView()
}
