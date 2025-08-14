import SwiftUI
import AVKit

struct LocalWallpaperItemView: View {
    let item: WallpaperItem
    @State private var isHovering = false
    @State private var thumbnailImage: Image?
    @State private var isShowingPreview = false
    @State private var isShowingDetails = false
    @State private var isButtonDisabled = false
    private let buttonDelay: Double = 0.5
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            if let thumbnailImage = thumbnailImage {
                thumbnailImage
                    .resizable()
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .cornerRadius(8)
            } else {
                Color.gray
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .cornerRadius(8)
            }
            
            if isHovering {
                HStack(spacing: 8) {
                    VideoNameLabel(text: item.fileUrl.lastPathComponent)
                    Spacer()
                    VideoFloatButton(text: "Preview", action: debouncedAction { isShowingPreview = true })
                    VideoFloatButton(text: "Details", action: debouncedAction(showDetails))
                    VideoFloatButton(text: "Play", action: debouncedAction(playVideo))
                    VideoFloatButton(text: "Delete", color: .red, action: debouncedAction(deleteDynamicWallpaper))
                }
                .padding(8)
            }
        }
        .sheet(isPresented: $isShowingPreview) {
            ZStack(alignment: .topLeading) {
                VideoPreviewView(videoURL: item.fileUrl)
                VideoCloseButton(action: { isShowingPreview = false })
            }
        }
        .sheet(isPresented: $isShowingDetails) {
            ZStack(alignment: .topLeading) {
                DetailsView(item: item)
                    .padding(20)
                VideoCloseButton(action: { isShowingDetails = false })
            }
        }
        .onAppear {
            generateThumbnail()
        }
        .onHover { hovering in
            withAnimation(.easeInOut) {
                isHovering = hovering
            }
        }
    }
    
    private func fileURL(for relativePath: String) -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent(relativePath)
    }
    
    private func showDetails() {
        isShowingDetails = true
    }
    
    private func generateThumbnail() {
        let asset = AVAsset(url: item.fileUrl)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        generator.generateCGImageAsynchronously(for: time) { cgImage, _, _ in
            if let cgImage = cgImage {
                DispatchQueue.main.async {
                    let nsImage = NSImage(cgImage: cgImage, size: .zero)
                    self.thumbnailImage = Image(nsImage: nsImage)
                }
            }
        }
    }
    
    private func playVideo() {
        let videoURL = item.fileUrl
        NotificationCenter.default.post(name: .playVideoUrlChanged, object: nil, userInfo: ["videoURL": videoURL])
    }
    
    private func debouncedAction(_ action: @escaping () -> Void) -> () -> Void {
        return {
            if !isButtonDisabled {
                isButtonDisabled = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
                    isButtonDisabled = false
                }
            }
        }
    }
    
    private func deleteDynamicWallpaper() {
        //        if DatabaseManger.shared.getPlayListItemByFileName(item.fileUrl.lastPathComponent) != nil {
        //            let alert = NSAlert()
        //            alert.messageText = NSLocalizedString("Cannot Delete", comment: "")
        //            alert.informativeText = NSLocalizedString("This wallpaper is in the playlist. Please remove it from the playlist before deleting.", comment: "")
        //            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        //            alert.alertStyle = .warning
        //            alert.runModal()
        //            return
        //        }
        //        
        //        let alert = NSAlert()
        //        alert.messageText = NSLocalizedString("Delete dynamic wallpaper", comment: "")
        //        alert.informativeText = NSLocalizedString(
        //            "Non-program-built-in dynamic wallpapers cannot be recovered after deletion and need to be redownloaded or imported.",
        //            comment: "")
        //        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        //        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        //        alert.alertStyle = .warning
        //        
        //        let response = alert.runModal()
        //        if response == .alertFirstButtonReturn {
        //            do {
        //                try FileManager.default.removeItem(at: item.fileUrl)
        //                Logger.info("Dynamic wallpaper deleted successfully: \(item.fileUrl)")
        //                LocalVideManger.shared.deleteLocalWallpaper(item: item)
        //                NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
        //            } catch {
        //                Logger.error("Failed to delete dynamic wallpaper: \(error)")
        //            }
        //        }
    }
}

#Preview {
    LocalWallpaperItemView(item: WallpaperItem(
        id: UUID(),
        title: "Sample Video",
        fileUrl: Bundle.main.url(forResource: "codelume_0", withExtension: "mp4")!,
        resolution: "1920x1080",
        fileSize: 123456,
        codec: "H.264",
        duration: 60.0,
        creationDate: Date()
    ))
}
