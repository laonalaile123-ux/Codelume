//
//  PlayingManager.swift
//  CodeLume
//
//  Created by lyke on 2025/5/30.
//

import Foundation

enum PlayMode: String, CaseIterable{
    case loop = "Loop"
    case sequence = "Sequence"
    case random = "Random"
}

class PlayingManager: ObservableObject {
    static let shared = PlayingManager()
    
    private var playList: [WallpaperItem] = []
    private var currentIndex: Int = 0
    private var playMode: PlayMode = .loop
    private var switchInterval: TimeInterval = 300
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadConfig()
        loadPlayList()
        subscribeNotifications()
        startTimer()
    }
    
    func setCurrentPlaying(uuid: UUID) {
        if let idx = playList.firstIndex(where: { $0.id == uuid }) {
            currentIndex = idx
            userDefaults.set(currentIndex, forKey: "currentPlayingId")
            notifyPlayItemChanged()
        }
    }
    
    func next() {
        switch playMode {
        case .loop:
            break
        case .sequence:
            currentIndex = (currentIndex + 1) % playList.count
            userDefaults.set(currentIndex, forKey: "currentPlayingId")
            notifyPlayItemChanged()
        case .random:
            if playList.count > 1 {
                var newIndex: Int
                repeat {
                    newIndex = Int.random(in: 0..<playList.count)
                } while newIndex == currentIndex
                currentIndex = newIndex
                userDefaults.set(currentIndex, forKey: "currentPlayingId")
            }
            notifyPlayItemChanged()
        }
    }
    
    func setPlayMode(_ mode: PlayMode) {
        playMode = mode
        userDefaults.set(mode.rawValue, forKey: "playMode")
        restartTimer()
    }
    
    func setSwitchInterval(_ interval: Interval) {
        switch interval {
        case Interval.fiveMinutes:
            switchInterval = 300
        case Interval.tenMinutes:
            switchInterval = 600
        case Interval.halfHour:
            switchInterval = 1800
        case Interval.oneHour:
            switchInterval = 3600
        case Interval.oneDay:
            switchInterval = 86400
        case Interval.oneWeek:
            switchInterval = 604800
        case Interval.oneMonth:
            switchInterval = 2592000
        }
        restartTimer()
    }
    
    func getCurrentItem() -> WallpaperItem? {
        return currentItem()
    }
    
    private func reloadPlayList() {
        let currentId = currentItem()?.id
        loadPlayList()
        if let currentId = currentId,
           let idx = playList.firstIndex(where: { $0.id == currentId }) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }
        userDefaults.set(currentIndex, forKey: "currentPlayingId")
        notifyPlayItemChanged()
    }
    
    private func currentItem() -> WallpaperItem? {
        guard !playList.isEmpty, currentIndex < playList.count else { return nil }
        return playList[currentIndex]
    }
    
    private func loadConfig() {
        if let modeRaw = userDefaults.string(forKey: "playMode"),
           let mode = PlayMode(rawValue: modeRaw) {
            playMode = mode
        }
        
        let interval = userDefaults.string(forKey: "switchInterval")
        setSwitchInterval(Interval(rawValue: interval ?? "Five minutes")!)

        currentIndex = userDefaults.integer(forKey: "currentPlayingId")
    }
    
    private func loadPlayList() {
        playList = LocalVideoManager.shared.getAllPlayListWallpapers()
    }
    
    private func subscribeNotifications() {
//        NotificationCenter.default.addObserver(self, selector: #selector(onConfigChanged), name: .playConfigChanged, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(onPlayListChanged), name: .refreshPlayList, object: nil)
    }
    
    @objc private func onConfigChanged(_ notification: Notification) {
        loadConfig()
        restartTimer()
    }
    
    @objc private func onPlayListChanged(_ notification: Notification) {
        reloadPlayList()
        restartTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = nil
        
        if playMode != .loop {
            timer = Timer.scheduledTimer(withTimeInterval: switchInterval, repeats: true) { [weak self] _ in
                if isAppFullScreen() {
                    return
                }
                self?.next()
            }
        }
    }
    
    private func restartTimer() {
        startTimer()
    }
    
    private func notifyPlayItemChanged() {
//        if let item = currentItem() {
//            LocalVideManger.shared.setPlaying(uuid: item.id)
//            NotificationCenter.default.post(name: .setWallpaperIsVisiable, object: false)
//            NotificationCenter.default.post(name: .playItemChanged, object: item)
//        }
    }
}
