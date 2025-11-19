import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
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
                }
                .padding(.horizontal)
                
                Button {
                    NSWorkspace.shared.open(URL(string: "https://www.douyin.com/user/MS4wLjABAAAAl1srMN6bnoQL8gBUFGUa3wQZp7KJ4WHfXyfz16Us2syzqhhKKM-iDCW64v5enW9w?from_tab_name=main&vid=7573053246886006052")!)
                } label: {
                    Text("Contact Us")
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    AboutView()
}
