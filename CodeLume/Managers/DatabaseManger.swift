import Foundation
import SQLite
import AppKit

// MARK: - 数据库管理类
final class DatabaseManger {
    static let shared = DatabaseManger()
    private var db: Connection?
    private let dbFileName = "codelume.sqlite3"
    
    private init() {
        openDatabase()
        createWallpaperTable()
        createScreenConfigTable()
    }
    
    private func openDatabase() {
        do {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbURL = docDir.appendingPathComponent(dbFileName)
            db = try Connection(dbURL.path)
            Logger.info("Database opened at: \(dbURL.path)")
        } catch {
            Logger.error("Failed to open database: \(error)")
        }
    }
    
    // MARK: - 本地屏幕数据
    private let screenConfigTable = Table("screen_config_table")
    private let idExp = Expression<String>("id")
    private let playbackTypeExp = Expression<String>("playbackType")
    private let wallpaperUrlExp = Expression<String?>("wallpaperUrl")
    private let isPlayingExp = Expression<Bool>("isPlaying")
    private let isMutedExp = Expression<Bool>("isMuted")
    private let volumeExp = Expression<Double>("volume")
    private let fillModeExp = Expression<String>("fillMode")
    private let physicalResolutionExp = Expression<String>("physicalResolution")
    
    func setScreenConfig(_ config: ScreenConfiguration) {
        guard let db = db else { return }
        do {
            let existingConfig = screenConfigTable.filter(idExp == config.id)
            let count = try db.scalar(existingConfig.count)
            if count > 0 {
                let update = existingConfig.update(
                    playbackTypeExp <- config.playbackType.rawValue,
                    wallpaperUrlExp <- config.wallpaperUrl?.path,
                    isPlayingExp <- config.isPlaying,
                    isMutedExp <- config.isMuted,
                    volumeExp <- config.volume,
                    fillModeExp <- config.fillMode.rawValue,
                    physicalResolutionExp <- config.physicalResolution
                )
                try db.run(update)
                Logger.info("Updated screen config for: \(config.id)")
            } else {
                let insert = screenConfigTable.insert(
                    idExp <- config.id,
                    playbackTypeExp <- config.playbackType.rawValue,
                    wallpaperUrlExp <- config.wallpaperUrl?.path,
                    isPlayingExp <- config.isPlaying,
                    isMutedExp <- config.isMuted,
                    volumeExp <- config.volume,
                    fillModeExp <- config.fillMode.rawValue,
                    physicalResolutionExp <- config.physicalResolution
                )
                try db.run(insert)
                Logger.info("Inserted screen config for: \(config.id)")
            }
            NotificationCenter.default.post(name: .screenConfigChanged, object: config.id)
        } catch {
            Logger.error("Failed to save screen config: \(error)")
        }
    }
    
    func getScreenConfig(for screenId: String) -> ScreenConfiguration? {
        guard let db = db else { return nil }
        do {
            let query = screenConfigTable.filter(idExp == screenId)
            if let row = try db.pluck(query) {
                let playbackType = PlaybackType(rawValue: row[playbackTypeExp]) ?? .video
                let wallpaperUrl = row[wallpaperUrlExp].flatMap { URL(fileURLWithPath: $0) }
                let fillMode = WallpaperFillMode(rawValue: row[fillModeExp]) ?? .fill
                return ScreenConfiguration(
                    id: screenId,
                    playbackType: playbackType,
                    wallpaperUrl: wallpaperUrl,
                    isPlaying: row[isPlayingExp],
                    isMuted: row[isMutedExp],
                    volume: row[volumeExp],
                    fillMode: fillMode,
                    physicalResolution: row[physicalResolutionExp]
                )
            }
        } catch {
            Logger.error("Failed to get screen config: \(error)")
        }
        return nil
    }
    // 考虑删除
    func isSetWallpaperUrl(url: URL) -> Bool {
        guard let db = db else { return false }
        do {
            let query = screenConfigTable.filter(wallpaperUrlExp == url.path)
            let count = try db.scalar(query.count)
            return count > 0
        } catch {
            Logger.error("Failed to check if url is in screen config: \(error)")
            return false
        }
    }
    
    func deleteScreenConfig(for screenId: String) {
        guard let db = db else { return }
        do {
            let config = screenConfigTable.filter(idExp == screenId)
            try db.run(config.delete())
            Logger.info("Deleted screen config for: \(screenId)")
        } catch {
            Logger.error("Failed to delete screen config: \(error)")
        }
    }
    
    func getAllScreenConfigs() -> [ScreenConfiguration] {
        guard let db = db else { return [] }
        var configs: [ScreenConfiguration] = []
        do {
            let rows = try db.prepare(screenConfigTable)
            for row in rows {
                let screenId = row[idExp]
                let playbackType = PlaybackType(rawValue: row[playbackTypeExp]) ?? .video
                let wallpaperUrl = row[wallpaperUrlExp].flatMap { URL(fileURLWithPath: $0) }
                let fillMode = WallpaperFillMode(rawValue: row[fillModeExp]) ?? .fill
                let config = ScreenConfiguration(
                    id: screenId,
                    playbackType: playbackType,
                    wallpaperUrl: wallpaperUrl,
                    isPlaying: row[isPlayingExp],
                    isMuted: row[isMutedExp],
                    volume: row[volumeExp],
                    fillMode: fillMode,
                    physicalResolution: row[physicalResolutionExp]
                )
                configs.append(config)
            }
        } catch {
            Logger.error("Failed to get all screen configs: \(error)")
        }
        return configs
    }
    
    private func createScreenConfigTable() {
        guard let db = db else { return }
        do {
            try db.run(screenConfigTable.create(ifNotExists: true) { tab in
                tab.column(idExp, primaryKey: true)
                tab.column(playbackTypeExp)
                tab.column(wallpaperUrlExp)
                tab.column(isPlayingExp)
                tab.column(isMutedExp)
                tab.column(volumeExp)
                tab.column(fillModeExp)
                tab.column(physicalResolutionExp)
                Logger.info("Create screen config table successfully.")
            })
        } catch {
            Logger.error("Failed to create screen config table: \(error)")
        }
    }
    
    // MARK: - 本地壁纸数据
    private let wallpaperTable = Table("wallpaper_table")
    private let wallpaperNameExp = Expression<String>("wallpaperName")

    // MARK: - public
    func addWallpaper(_ wallpaperName: String) {
        guard let db = db else { return }
        
        do {
            let query = wallpaperTable.filter(wallpaperNameExp == wallpaperName)
            let count = try db.scalar(query.count)
            
            if count > 0 {
                Logger.warning("Wallpaper already exists in database: \(wallpaperName)")
                return
            }
            
            let insert = wallpaperTable.insert(
                wallpaperNameExp <- wallpaperName,
            )
            
            try db.run(insert)
            Logger.info("Wallpaper added successfully: \(wallpaperName)")
            
        } catch {
            Logger.error("Failed to insert wallpaper: \(error)")
        }
    }

    func getAllWallpapers() -> [String] {
        guard let db = db else { return [] }
        var wallpapers: [String] = []
        do {
            let rows = try db.prepare(wallpaperTable)
            for row in rows {
                let wallpaper = row[wallpaperNameExp]
                wallpapers.append(wallpaper)
            }
        } catch {
            Logger.error("Failed to fetch wallpapers: \(error)")
        }
        return wallpapers
    }
    
    func deleteWallpaper(by wallpaperName: String) {
        guard let db = db else { return }
        let wallpaper = wallpaperTable.filter(wallpaperNameExp == wallpaperName)
        do {
            if let row = try db.pluck(wallpaper) {
                let file = row[wallpaperNameExp]
                deleteWallpaperFile(at: file)
            }
            try db.run(wallpaper.delete())
            Logger.info("Deleted wallpaper: \(wallpaperName)")
        } catch {
            Logger.error("Failed to delete wallpaper: \(error)") 
        }
    }
    
    // MARK: - private
    private func createWallpaperTable() {
        guard let db = db else { return }
        do {
            try db.run(wallpaperTable.create(ifNotExists: true){ tab in
                tab.column(wallpaperNameExp, primaryKey: true)
                Logger.info("Create wallpaper table successfully.")
            })
        } catch {
            Logger.error("Failed to create wallpaper table: \(error)")
        }
    }
}
