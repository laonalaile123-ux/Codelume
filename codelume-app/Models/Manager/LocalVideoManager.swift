//
//  LocalVideManger.swift
//  CodeLume
//
//  Created by lyke on 2025/5/12.
//

import Foundation
import SQLite

final class LocalVideoManager {
    static let shared = LocalVideoManager()
    private var db: Connection?
    private let dbFileName = "codelume.sqlite3"
    
    private var localWallpaperCache: [WallpaperItem] = []
    private var playListCache: [WallpaperItem] = []
    
    private let playListTable = Table("playlisttable")
    private let localWallpaperTable = Table("localwallpaperstable")
    
    private let uuidExp = Expression<String>("uuid")
    private let titleExp = Expression<String>("title")
    private let filePathExp = Expression<String>("filePath")
    private let categoryExp = Expression<String>("category")
    private let resolutionExp = Expression<String>("resolution")
    private let fileSizeExp = Expression<Int>("fileSize")
    private let codecExp = Expression<String>("codec")
    private let durationExp = Expression<Double>("duration")
    private let creationDateExp = Expression<Date>("creationDate")
    private let tagsExp = Expression<String>("tags")
    private let cacheQueue = DispatchQueue(label: "com.codelume.LocalVideManger.cacheQueue", attributes: .concurrent)
    
    
    private init() {
        openDatabase()
        createPlayListTable()
        createLocalWallpaperTable()
        cleanInvalidLocalWallpapers()
        preloadAllData()
    }
    
    func setPlaying(uuid: UUID) {
        cacheQueue.async(flags: .barrier) {
            for i in self.localWallpaperCache.indices {
                self.localWallpaperCache[i].isPlaying = (self.localWallpaperCache[i].id == uuid)
            }
            for i in self.playListCache.indices {
                self.playListCache[i].isPlaying = (self.playListCache[i].id == uuid)
            }
        }
    }
    
    func isPlaying(uuid: UUID) -> Bool {
        var result = false
        cacheQueue.sync {
            if let item = self.localWallpaperCache.first(where: { $0.id == uuid }) {
                result = item.isPlaying
            } else if let item = self.playListCache.first(where: { $0.id == uuid }) {
                result = item.isPlaying
            }
        }
        return result
    }
    
    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func preloadAllData() {
        localWallpaperCache = loadLocalWallpapers()
        playListCache = loadPlayListWallpapers()
    }
    
    private func fullFilePath(for relativePath: String) -> String {
        if relativePath.hasPrefix("/") {
            return relativePath
        }
        return documentsDirectory().appendingPathComponent(relativePath).path
    }
    
    private func cleanInvalidLocalWallpapers() {
        guard let db = db else { return }
        do {
            let rows = try db.prepare(localWallpaperTable)
            for row in rows {
                let filePath = row[filePathExp]
                if !fileExists(atPath: filePath) {
                    print("File not found for \(filePath), removing from database.")
                    let wallpaper = localWallpaperTable.filter(filePathExp == filePath)
                    try db.run(wallpaper.delete())
                }
            }
        } catch {
            print("Failed to clean invalid local wallpapers: \(error)")
        }
    }
    
    private func fileExists(atPath path: String) -> Bool {
        let fullPath = fullFilePath(for: path)
        return FileManager.default.fileExists(atPath: fullPath)
    }
    
    private func deleteFile(atPath path: String) {
        let fullPath = fullFilePath(for: path)
        if fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: fullPath)
                print("Deleted file at path: \(fullPath)")
            } catch {
                print("Failed to delete file at path: \(fullPath), error: \(error)")
            }
        }
    }
    
    private func openDatabase() {
        do {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbURL = docDir.appendingPathComponent(dbFileName)
            db = try Connection(dbURL.path)
            print("Database opened at: \(dbURL.path)")
        } catch {
            print("Failed to open database: \(error)")
        }
    }
    
    private func createPlayListTable() {
        guard let db = db else { return }
        do {
            try db.run(playListTable.create(ifNotExists: true){ tab in
                tab.column(uuidExp, primaryKey: true)
                tab.column(titleExp)
                tab.column(filePathExp, unique: true)
                tab.column(categoryExp)
                tab.column(resolutionExp)
                tab.column(fileSizeExp)
                tab.column(codecExp)
                tab.column(durationExp)
                tab.column(creationDateExp)
                tab.column(tagsExp)
                print("Create play list table successfully.")
            })
        } catch {
            print("Failed to create play list table: \(error)")
        }
    }
    
    private func createLocalWallpaperTable() {
        guard let db = db else { return }
        do {
            try db.run(localWallpaperTable.create(ifNotExists: true) { tab in
                tab.column(uuidExp, primaryKey: true)
                tab.column(titleExp)
                tab.column(filePathExp, unique: true)
                tab.column(categoryExp)
                tab.column(resolutionExp)
                tab.column(fileSizeExp)
                tab.column(codecExp)
                tab.column(durationExp)
                tab.column(creationDateExp)
                tab.column(tagsExp)
                print("Create local wallpapers table successfully.")
            })
        } catch {
            print("Failed to create local wallpapers table: \(error)")
        }
    }
    
    func addLocalWallpaper(_ video: WallpaperItem) {
        guard fileExists(atPath: video.filePath) else {
            print("File does not exist at path: \(video.filePath), not adding to database.")
            return
        }
        guard let db = db else { return }
        let insert = localWallpaperTable.insert(
            uuidExp <- video.id.uuidString,
            titleExp <- video.title,
            filePathExp <- video.filePath,
            categoryExp <- video.category,
            resolutionExp <- video.resolution,
            fileSizeExp <- video.fileSize,
            codecExp <- video.codec,
            durationExp <- video.duration,
            creationDateExp <- video.creationDate,
            tagsExp <- video.tags.joined(separator: ",")
        )
        do {
            try db.run(insert)
            
        } catch {
            print("Failed to insert local video: \(error)")
        }
        refreshCache()
    }
    
    
    func deleteLocalWallpaper(by uuid: UUID) {
        guard let db = db else { return }
        let inPlaylist = playListTable.filter(uuidExp == uuid.uuidString)
        do {
            let count = try db.scalar(inPlaylist.count)
            if count > 0 {
                print("This video is already in the playlist. Please remove it from the playlist first!")
                return
            }
            
            if let row = try db.pluck(localWallpaperTable.filter(uuidExp == uuid.uuidString)) {
                let filePath = row[filePathExp]
                deleteFile(atPath: filePath)
            }
            let video = localWallpaperTable.filter(uuidExp == uuid.uuidString)
            try db.run(video.delete())
        } catch {
            print("Failed to delete local video: \(error)")
        }
        refreshCache()
    }
    
    func addToPlaylist(uuid: UUID) {
        guard let db = db else { return }
        let query = localWallpaperTable.filter(uuidExp == uuid.uuidString)
        do {
            if let row = try db.pluck(query) {
                let insert = playListTable.insert(
                    uuidExp <- row[uuidExp],
                    titleExp <- row[titleExp],
                    filePathExp <- row[filePathExp],
                    categoryExp <- row[categoryExp],
                    resolutionExp <- row[resolutionExp],
                    fileSizeExp <- row[fileSizeExp],
                    codecExp <- row[codecExp],
                    durationExp <- row[durationExp],
                    creationDateExp <- row[creationDateExp],
                    tagsExp <- row[tagsExp]
                )
                try db.run(insert)
            } else {
                print("Only local videos can be added to the playlist!")
            }
        } catch {
            print("Failed to add to playlist: \(error)")
        }
        refreshCache()
    }
    
func removeFromPlaylist(by uuid: UUID) {
        guard let db = db else { return }
        let wallpaper = playListTable.filter(uuidExp == uuid.uuidString)
        do {
            
            try db.run(wallpaper.delete())
            print("remove \(uuid.uuidString) from play list.")
        } catch {
            print("Failed to remove from playlist: \(error)")
        }
        refreshCache()
    }
    
    func deleteLocalWallpaper(byFilePath filePath: String) {
        guard let db = db else { return }
        let inPlaylist = playListTable.filter(filePathExp == filePath)
        do {
            let count = try db.scalar(inPlaylist.count)
            if count > 0 {
                print("This video is already in the playlist. Please remove it from the playlist first!")
                return
            }
            
            deleteFile(atPath: filePath)
            let wallpaper = localWallpaperTable.filter(filePathExp == filePath)
            try db.run(wallpaper.delete())
            print("remove \(filePath) from local wallpapers.")
        } catch {
            print("Failed to remove from local wallpapers by filePath: \(error)")
        }
        refreshCache()
    }
    
    func removeFromPlaylist(byFilePath filePath: String) {
        guard let db = db else { return }
        let wallpaper = playListTable.filter(filePathExp == filePath)
        do {
            try db.run(wallpaper.delete())
            print("remove \(filePath) from play list.")
        } catch {
            print("Failed to remove from play list by filePath: \(error)")
        }
        refreshCache()
    }
    
    func deleteLocalWallpaper(item: WallpaperItem) {
        deleteLocalWallpaper(by: item.id)
    }
    
    func removeFromPlaylist(item: WallpaperItem) {
        removeFromPlaylist(by: item.id)
    }
    
    func getAllLocalWallpaperUUIDs() -> [UUID] {
        guard let db = db else { return [] }
        do {
            return try db.prepare(localWallpaperTable).compactMap { row in
                UUID(uuidString: row[uuidExp])
            }
        } catch {
            print("Failed to fetch UUIDs: \(error)")
            return []
        }
    }
    
    private func loadLocalWallpapers() -> [WallpaperItem] {
        guard let db = db else { return [] }
        do {
            let rows = try db.prepare(localWallpaperTable)
            return rows.compactMap { row in
                WallpaperItem(
                    id: UUID(uuidString: row[uuidExp]) ?? UUID(),
                    title: row[titleExp],
                    filePath: row[filePathExp],
                    category: row[categoryExp],
                    resolution: row[resolutionExp],
                    fileSize: row[fileSizeExp],
                    codec: row[codecExp],
                    duration: row[durationExp],
                    creationDate: row[creationDateExp],
                    tags: row[tagsExp].split(separator: ",").map { String($0) }
                )
            }
        } catch {
            print("Failed to fetch local wallpapers: \(error)")
            return []
        }
    }
    
    private func loadPlayListWallpapers() -> [WallpaperItem] {
        guard let db = db else { return [] }
        do {
            let rows = try db.prepare(playListTable)
            return rows.compactMap { row in
                WallpaperItem(
                    id: UUID(uuidString: row[uuidExp]) ?? UUID(),
                    title: row[titleExp],
                    filePath: row[filePathExp],
                    category: row[categoryExp],
                    resolution: row[resolutionExp],
                    fileSize: row[fileSizeExp],
                    codec: row[codecExp],
                    duration: row[durationExp],
                    creationDate: row[creationDateExp],
                    tags: row[tagsExp].split(separator: ",").map { String($0) }
                )
            }
        } catch {
            print("Failed to fetch play list wallpapers: \(error)")
            return []
        }
    }
    
    func getAllLocalWallpapers() -> [WallpaperItem] {
        return localWallpaperCache
    }
    
    func getAllPlayListWallpapers() -> [WallpaperItem] {
        return playListCache
    }
    
    func getWallpaperItemByFileName(_ fileName: String) -> WallpaperItem? {
        return localWallpaperCache.first { $0.filePath.hasSuffix("/" + fileName) || $0.filePath == fileName }
    }
    
    func getPlayListItemByFileName(_ fileName: String) -> WallpaperItem? {
        return playListCache.first { $0.filePath.hasSuffix("/" + fileName) || $0.filePath == fileName }
    }
    
    private func refreshCache() {
        preloadAllData()
    }

}
