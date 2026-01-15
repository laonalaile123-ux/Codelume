import SwiftUI

struct ScreenSaverView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("CodeLume Screen Saver")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Screen Saver Introduction")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Screen savers originated in the CRT monitor era, primarily designed to prevent 'burn-in' caused by static images remaining on the screen for extended periods. This phenomenon occurs when electron beams continuously bombard the same phosphor areas, causing permanent physical damage. As technology evolved to LCD and OLED displays, screen savers transformed from mere hardware protection to versatile platforms that integrate security, energy management, information display, and personalized experiences.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    Text("CodeLume offers a dedicated screen saver module that allows users to set their current dynamic wallpapers as screen savers after downloading and installing it. This creates a seamless visual transition between active desktop environments and idle states, extending dynamic aesthetics throughout the entire device usage cycle while ensuring privacy security and maintaining a consistent immersive visual experience.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Spacer()
                    Button(action: downloadScreensaver) {
                        Text("Download Screen Saver")
                            .padding(6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Link("View installation instructions on GitHub.",
                         destination: URL(string: "https://github.com/guang-zi-yu/CodelumeSaver.git")!)
                    .font(.caption)
                    .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.top, 5)
                
                Spacer()
                    .frame(height: 40)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    ScreenSaverView()
        .frame(width: 600, height: 400)
}

