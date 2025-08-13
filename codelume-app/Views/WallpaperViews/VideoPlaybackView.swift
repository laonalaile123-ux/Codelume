import AppKit
import AVKit

class VideoPlaybackView: AVPlayerView {
    // 播放状态属性
    var isPlaying: Bool {
        get {
            return player?.rate != 0
        }
        set {
            if newValue {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }

    // 音量属性
    var volume: Float {
        get {
            return player?.volume ?? 1.0
        }
        set {
            player?.volume = newValue
        }
    }
    init(frame: NSRect, config: ScreenConfiguration) {
        super.init(frame: frame)
        setupPlayer(with: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(with config: ScreenConfiguration) {
//        if !config.contentPath.isEmpty, let url = try? URL(fileURLWithPath: config.contentPath) {
//            let player = AVPlayer(url: url)
//            self.player = player
//            player.volume = config.volume
//            if config.isPlaying {
//                player.play()
//            }
//        }
//        if !config.contentPath.isEmpty, let url = try? URL(fileURLWithPath: config.contentPath) {
//            let player = AVPlayer(url: url)
//            self.player = player
//            player.volume = config.volume
//            if config.isPlaying {
//                player.play()
//            }
//        }
    }
}
