//
//  PlayListItemView.swift
//  CodeLume
//
//  Created by lyke on 2025/5/28.
//

import SwiftUI
import AVKit

struct PlayListItemView: View {
    let item: WallpaperItem
    var onRemove: (() -> Void)? = nil
    @State private var isHovering = false
    @State private var thumbnailImage: Image?
    @State private var isShowingPreview = false
    
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
                    VideoNameLabel(text: URL(fileURLWithPath: item.filePath).lastPathComponent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VideoFloatButton(text: "Preview", action: { isShowingPreview = true})
                    VideoFloatButton(text: "Set", action: setAsCurrentWallpaper)
                    VideoFloatButton(text: "Remove",color: .red, action: removeFormPlayList)
                }
                .padding(8)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $isShowingPreview) {
            ZStack(alignment: .topLeading) {
                VideoPreviewView(videoURL: fileURL(for: item.filePath))
                VideoCloseButton(action: { isShowingPreview = false })
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
    
    private func generateThumbnail() {
        let asset = AVAsset(url: fileURL(for: item.filePath))
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
    
    private func setAsCurrentWallpaper() {
        PlayingManager.shared.setCurrentPlaying(uuid: item.id)
    }
    
    private func removeFormPlayList() {
        if isWallpaperPlaying() {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Removal failed", comment: "")
            alert.informativeText = NSLocalizedString(
                "This dynamic wallpaper is currently in use.",
                comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.alertStyle = .warning
            alert.runModal()
            return
        }
//        LocalVideManger.shared.removeFromPlaylist(item: item)
        onRemove?()
    }
    
    private func isWallpaperPlaying() -> Bool {
        false
//        return LocalVideManger.shared.isPlaying(uuid: item.id)
    }
}

#Preview {
    PlayListItemView(item: WallpaperItem(
        id: UUID(),
        title: "Sample Video",
        filePath: "video/test_1.mp4",
        category: "Scenery",
        resolution: "1920x1080",
        fileSize: 123456,
        codec: "H.264",
        duration: 60.0,
        creationDate: Date(),
        tags: ["scenery", "HD"]
    ))
}
