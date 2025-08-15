import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            VStack {
                List {
//                    NavigationLink("Playing", destination: PlayingView()
//                        .navigationTitle("Playing"))
                    
                    NavigationLink("LocalVideos", destination: LocalVideoView()
                        .navigationTitle("LocalVideos"))
                }
                .listStyle(.sidebar)
                .frame(minWidth: 220)
                
                Spacer()
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
            }
        } detail: {
            LocalVideoView()
                .navigationTitle("LocalVideos")
        }
        .presentedWindowStyle(.automatic)
    }
}

#Preview {
    HomeView()
}
