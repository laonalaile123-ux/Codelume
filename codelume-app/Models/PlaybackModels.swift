import AppKit
import Foundation

// 播放内容类型枚举
enum PlaybackType: String, Codable {
    case video
    case spriteKit
    case sceneKit
}

// 屏幕播放配置模型
struct ScreenConfiguration: Codable {
    let screenIdentifier: String
    var playbackType: PlaybackType
    var contentPath: String
    var volume: Float = 1.0
    var isPlaying: Bool = false
    
    // 初始化方法
    init(screen: NSScreen, playbackType: PlaybackType = .video, contentPath: String = "") {
        // 使用屏幕的唯一标识符
        self.screenIdentifier = screen.identifier
        self.playbackType = playbackType
        self.contentPath = contentPath
    }
}