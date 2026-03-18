import AppKit
import Foundation
import SwiftUI
import CodelumeBundle

struct LocalWallpapersView: View {
    @State private var wallpaperItems: [URL] = []
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        Group {
            ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(wallpaperItems, id: \.self) { url in
                    LocalWallpaperHubCard(wallpaperURL: url)
                }
            }
            .padding()
        }
        .onAppear {
            loadLocalWallpapers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshLocalWallpaperList)) { _ in
            Logger.info("Received refresh local wallpapers notification.")
            loadLocalWallpapers()
        }   
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func loadLocalWallpapers() {
        let wallpapers = DatabaseManger.shared.getAllWallpapers()
        Logger.info("load \(wallpapers.count) wallpapers.")
        
        guard let wallpapersSaveURL = getWallpaperSaveURL() else {
            Logger.error("Failed to get wallpapers save URL.")
            return
        }
        
        wallpaperItems.removeAll()
        
        for wallpaper in wallpapers {
            let wallpaperURL = wallpapersSaveURL.appendingPathComponent("\(wallpaper).bundle")
            wallpaperItems.append(wallpaperURL)
        }
    }
}

private struct LocalWallpaperHubCard: View {
    let wallpaperURL: URL
    @State private var isShowingPreview = false
    @State private var isShowingScreenSelector = false
    @StateObject private var viewModel: LocalWallpaperHubCardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LocalBundleStaticPreview(bundleURL: wallpaperURL)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Text(viewModel.displayName)
                    .font(.headline)
                    .lineLimit(1)

                WallpaperTypeLabel(type: viewModel.typeLabel)

                Spacer()
            }

            if let wallpaperVideoInfo = viewModel.videoInfo {
                WallpaperVideoInfoInline(info: wallpaperVideoInfo, isLoading: false)
            } else {
                Text("")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text(viewModel.descriptionText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

            HStack(spacing: 8) {
                Spacer()

                Button {
                    isShowingPreview = true
                } label: {
                    Label("Preview", systemImage: "eye")
                }
                .buttonStyle(.bordered)

                Button {
                    exportBundle()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    deleteVideo()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)

                Button {
                    isShowingScreenSelector = true
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .sheet(isPresented: $isShowingPreview) {
            WallpaperPreviewView(url: wallpaperURL)
        }
        .sheet(isPresented: $isShowingScreenSelector) {
            ScreenSelectorView(screens: NSScreen.screens, onSelect: handleScreenSelection)
        }
        .task(id: wallpaperURL) {
            await viewModel.loadIfNeeded(bundleURL: wallpaperURL)
        }
    }

    init(wallpaperURL: URL) {
        self.wallpaperURL = wallpaperURL
        _viewModel = StateObject(wrappedValue: LocalWallpaperHubCardViewModel())
    }

    private func handleScreenSelection(screen: NSScreen?) {
        guard let screen = screen else {
            isShowingScreenSelector = false
            return
        }

        if screen.identifier == "AllScreens" {
            ScreenManager.shared.updateAllScreensWallpaper(wallpaperURL: wallpaperURL)
            NotificationCenter.default.post(name: .wallpaperBundleChanged, object: nil, userInfo: [:])
        } else {
            ScreenManager.shared.updateScreenWallpaper(screenId: screen.identifier, wallpaperURL: wallpaperURL)
            NotificationCenter.default.post(name: .wallpaperBundleChanged, object: nil, userInfo: ["id": screen.identifier])
        }

        isShowingScreenSelector = false
    }

    private func exportBundle() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = NSLocalizedString("Export", comment: "")
        panel.message = NSLocalizedString("Choose a folder to export this wallpaper bundle.", comment: "")

        panel.begin { response in
            guard response == .OK, let directoryURL = panel.url else { return }

            let destinationURL = directoryURL.appendingPathComponent(wallpaperURL.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: wallpaperURL, to: destinationURL)
                Alert(title: "Export Success", message: "Wallpaper bundle exported successfully.")
            } catch {
                Alert(title: "Export Failed", dynamicMessage: error.localizedDescription, style: .warning)
            }
        }
    }

    private func deleteVideo() {
        let screenConfigs = ScreenManager.shared.screenConfigurations
        let isUsed = screenConfigs.contains { $0.wallpaperUrl == wallpaperURL }

        if isUsed {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Cannot Delete", comment: "")
            alert.informativeText = NSLocalizedString("This video is currently being used by a screen and cannot be deleted.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Delete this video?", comment: "")
        alert.informativeText = NSLocalizedString(
            "Non-program-built-in local video cannot be recovered after deletion and need to be redownloaded or imported.",
            comment: "")
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.alertStyle = .warning

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let wallpaperName = wallpaperURL.deletingPathExtension().lastPathComponent
            DatabaseManger.shared.deleteWallpaper(by: wallpaperName)
            NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
            Logger.info("Local wallpaper deleted successfully: \(wallpaperURL)")
        }
    }
}

private struct LocalBundleStaticPreview: View {
    let bundleURL: URL
    @State private var previewImage: Image?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if let previewImage {
                previewImage
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            loadTask?.cancel()
            loadTask = Task {
                await loadPreviewImage()
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadPreviewImage() async {
        if let cached = LocalWallpaperPreviewImageCache.shared.image(for: bundleURL) {
            await MainActor.run { previewImage = Image(nsImage: cached) }
            return
        }

        // Prefer CodelumeBundle standard preview path: preview/preview.png
        let standardPreviewURL = bundleURL.appendingPathComponent(BundleResources.preview)
        // Backward compatibility: older bundles used Preview/Preview.(png|jpg)
        let legacyPNG = bundleURL.appendingPathComponent("Preview/Preview.png")
        let legacyJPG = bundleURL.appendingPathComponent("Preview/Preview.jpg")

        let imageURL: URL
        if FileManager.default.fileExists(atPath: standardPreviewURL.path) {
            imageURL = standardPreviewURL
        } else if FileManager.default.fileExists(atPath: legacyPNG.path) {
            imageURL = legacyPNG
        } else {
            imageURL = legacyJPG
        }

        let nsImage: NSImage? = await Task.detached(priority: .utility) {
            return NSImage(contentsOf: imageURL)
        }.value

        guard let nsImage else { return }
        LocalWallpaperPreviewImageCache.shared.setImage(nsImage, for: bundleURL)
        await MainActor.run { previewImage = Image(nsImage: nsImage) }
    }
}

#if DEBUG
#Preview {
    LocalWallpapersView()
}
#endif

@MainActor
private final class LocalWallpaperHubCardViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var descriptionText: String = "Stored in local wallpaper bundles."
    @Published var videoInfo: WallpaperVideoInfoTable?
    @Published var typeLabel: String = ""

    private var loadedBundleURL: URL?

    func loadIfNeeded(bundleURL: URL) async {
        guard loadedBundleURL != bundleURL else { return }
        loadedBundleURL = bundleURL

        let fallbackName = bundleURL.deletingPathExtension().lastPathComponent
        displayName = fallbackName
        descriptionText = "Stored in local wallpaper bundles."
        videoInfo = nil
        typeLabel = ""

        let info: LocalWallpaperBundleInfo? = await Task.detached(priority: .utility) {
            return LocalWallpaperBundleInfoLoader.load(bundleURL: bundleURL)
        }.value

        guard let info else { return }

        displayName = info.displayName.isEmpty ? fallbackName : info.displayName
        descriptionText = info.descriptionText.isEmpty ? "Stored in local wallpaper bundles." : info.descriptionText
        videoInfo = info.videoInfo
        typeLabel = info.type
    }
}

private struct LocalWallpaperBundleInfo {
    let displayName: String
    let descriptionText: String
    let type: String
    let videoInfo: WallpaperVideoInfoTable?
}

private enum LocalWallpaperBundleInfoLoader {
    static func load(bundleURL: URL) -> LocalWallpaperBundleInfo? {
        let base = BaseBundle()
        guard base.open(wallpaperUrl: bundleURL) else { return nil }

        let displayName = base.bundleInfo.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptionText = base.bundleInfo.description.trimmingCharacters(in: .whitespacesAndNewlines)

        let type = base.bundleInfo.type.rawValue.lowercased()

        let videoInfo: WallpaperVideoInfoTable? = {
            guard base.bundleInfo.type == .video else { return nil }
            let video = VideoBundle()
            guard video.open(wallpaperUrl: bundleURL) else { return nil }
            let info = video.videoInfo
            return WallpaperVideoInfoTable(
                wallpaperId: UUID(),
                width: info.width,
                height: info.height,
                sizeBytes: Int64(info.size),
                duration: info.duration,
                format: info.format.rawValue,
                loop: info.loop,
                isEncrypted: info.encrypted,
                keyId: nil
            )
        }()

        return LocalWallpaperBundleInfo(
            displayName: displayName,
            descriptionText: descriptionText,
            type: type,
            videoInfo: videoInfo
        )
    }
}

private final class LocalWallpaperPreviewImageCache {
    static let shared = LocalWallpaperPreviewImageCache()
    private let cache = NSCache<NSString, NSImage>()

    func image(for bundleURL: URL) -> NSImage? {
        cache.object(forKey: bundleURL.path as NSString)
    }

    func setImage(_ image: NSImage, for bundleURL: URL) {
        cache.setObject(image, forKey: bundleURL.path as NSString)
    }
}

