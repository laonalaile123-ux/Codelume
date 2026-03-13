import SwiftUI

struct PreviewWallpaperGIF: View {
    let url: URL
    @State private var retryID = 0
    @State private var gifData: Data?
    @State private var isLoading = false
    @State private var loadFailed = false
    
    var body: some View {
        ZStack {
            if let gifData {
                AnimatedGIF(data: gifData)
            } else if isLoading {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                ProgressView()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                if loadFailed {
                    Button {
                        loadFailed = false
                        gifData = nil
                        isLoading = false
                        retryID += 1
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                            Text("Retry")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .id(retryID)
        .task(id: retryID) {
            await loadGIF()
        }
        .clipped()
    }
    
    private func loadGIF() async {
        isLoading = true
        loadFailed = false
        gifData = nil
        defer { isLoading = false }
        
        if let cachedData = GIFDataCache.data(for: url) {
            gifData = cachedData
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            let (data, _) = try await URLSession.shared.data(for: request)
            guard GIFAnimation(data: data) != nil else {
                loadFailed = true
                return
            }
            GIFDataCache.store(data, for: url)
            gifData = data
        } catch {
            loadFailed = true
        }
    }
    
    private enum GIFDataCache {
        private static let cache = NSCache<NSURL, NSData>()
        
        static func data(for url: URL) -> Data? {
            cache.object(forKey: url as NSURL) as Data?
        }
        
        static func store(_ data: Data, for url: URL) {
            cache.setObject(data as NSData, forKey: url as NSURL)
        }
    }
}
