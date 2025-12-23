import Foundation
import Supabase

// MARK: - Supabase 管理类
class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    private let supabaseUrl = URL(string: "https://kpvqflkypukhzkzttcwv.supabase.co")!
    private let supabaseKey = "sb_publishable_2osoNibBOvhyMmv6fyfOOw_hFo9fUa4"
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey,
        )
    }

    // 获取所有动态壁纸
    func getAllWallpaperBundlesInfo() async throws -> [URL] {
        var previewImageURLs: [URL] = []
        let response: [WallpaperTable] = try await client
            .from("wallpapers")
            .select()
            .execute()
            .value
        print("Get \(response.count) wallpapers from Supabase.")
        for wallpaper in response {
            // 下载 bundle
            let bundleURL = await downloadBundleInfo(name: wallpaper.fileName)
           previewImageURLs.append(bundleURL!)
        }
        return previewImageURLs
    }
    
    func downloadBundleInfo(name: String) async -> URL? {
        //在 tmp 目录下创建 bundle 目录
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tmpDir = documentsDir.appendingPathComponent("tmp")
        let bundleURL = tmpDir.appendingPathComponent("\(name).bundle")
        let videoDir = bundleURL.appendingPathComponent("Video")
        let previewDir = bundleURL.appendingPathComponent("Preview")
        let previewImageURL = previewDir.appendingPathComponent("Preview.jpg")
        let infoPlistURL = bundleURL.appendingPathComponent("Info.plist")
        let videoInfoURL = videoDir.appendingPathComponent("Video.plist")

        if FileManager.default.fileExists(atPath: bundleURL.path) {
            do {
                try FileManager.default.removeItem(at: bundleURL)
            } catch {
                print("Create bundle directory failed.")
            }
        }

        do {
            try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: videoDir, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: previewDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Create bundle directory failed.")
            return nil
        }
        //下载 Preview.jpg，Info.plist，Video.plist
        do {
            let previewImageData = try await client.storage
                .from("wallpapers")  // 桶名称
                .download(path: "\(name).bundle/Preview/Preview.jpg")  // 完整路径
            try previewImageData.write(to: previewImageURL)
            let infoPlistData = try await client.storage
                .from("wallpapers")  // 桶名称
                .download(path: "\(name).bundle/Info.plist")  // 完整路径
            try infoPlistData.write(to: infoPlistURL)
            let videoInfoData = try await client.storage
                .from("wallpapers")  // 桶名称
                .download(path: "\(name).bundle/Video/Video.plist")  // 完整路径
            try videoInfoData.write(to: videoInfoURL)
        } catch {
            print("Download bundle files failed.")
            return nil
        }

        Logger.info("Download bundle \(bundleURL) info success.")
        return bundleURL
    }

    func downloadWallpaper(name: String) async -> Bool {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tmpDir = documentsDir.appendingPathComponent("tmp")
        let bundleURL = tmpDir.appendingPathComponent("\(name).bundle")
        let videoDir = bundleURL.appendingPathComponent("Video")

        // 从 video.plist 中获取视频格式
        let videoInfoURL = videoDir.appendingPathComponent("Video.plist")
        let videoInfo = try? PropertyListSerialization.propertyList(from: Data(contentsOf: videoInfoURL), format: nil) as? [String: Any]
        let videoFormat = videoInfo?["format"] as? String ?? "mp4"
        Logger.info("Download video file name: \(name).bundle/Video/Wallpaper.\(videoFormat) start.")
        do {
            let videoData = try await client.storage
                .from("wallpapers")  // 桶名称
                .download(path: "\(name).bundle/Video/Wallpaper.\(videoFormat)") 
            Logger.info("Download video file \(videoDir.appendingPathComponent("Wallpaper.\(videoFormat)")) success.")
            try videoData.write(to: videoDir.appendingPathComponent("Wallpaper.\(videoFormat)"))
        } catch {
            print("Download video file failed.")
            return false
        }
        
        Logger.info("Download video file \(videoDir.appendingPathComponent("Wallpaper.\(videoFormat)")) success.")
        return true
    }
}
