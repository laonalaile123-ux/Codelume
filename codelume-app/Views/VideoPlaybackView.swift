import AppKit
import AVKit

// 视频播放视图
class VideoPlaybackView: AVPlayerView {
    init(frame: NSRect, config: ScreenConfiguration) {
        super.init(frame: frame)
        setupPlayer(with: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(with config: ScreenConfiguration) {
        if !config.contentPath.isEmpty, let url = try? URL(fileURLWithPath: config.contentPath) {
            let player = AVPlayer(url: url)
            self.player = player
            player.volume = config.volume
            if config.isPlaying {
                player.play()
            }
        }
    }
}
