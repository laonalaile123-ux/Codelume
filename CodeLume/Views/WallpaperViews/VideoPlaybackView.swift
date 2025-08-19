import AppKit
import AVKit

class VideoPlaybackView: AVPlayerView {
    private var isPlaying = true
    private var playScreen : NSScreen = NSScreen.main!

    func startMonitoringNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenPlayStateChanged),
            name: .screenPlayStateChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: .playbackStateChanged,
            object: nil
        )
    }

    func releaseResources() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeObserver(self, name: .screenPlayStateChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .playbackStateChanged, object: nil)
    }


    @objc private func handlePlaybackDidEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero) {
                [weak self] _ in
                self?.player?.play()
            }
        }
    }

    @objc private func handleScreenPlayStateChanged(notification: Notification) {
        if !isPlaying {
            return
        }

        if let screenId = notification.object as? String {
            if screenId == playScreen.identifier {
                if let shouldPlay = notification.userInfo?["isPlaying"] as? Bool {
                    if shouldPlay {
                        Logger.info("Screen play state changed to playing.")
//                        player?.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
                        player?.play()
                    } else {
                        Logger.info("Screen play state changed to paused.")
                        player?.pause()
                        player?.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
                    }
                }
            }
        }
    }

    @objc private func handlePlaybackStateChanged(notification: Notification) {
        if let isPlaying = notification.userInfo?["isPlaying"] as? Bool {
            if isPlaying {
                Logger.info("Playback state changed to playing.")
                self.isPlaying = true
                
                player?.play()
            } else {
                Logger.info("Playback state changed to paused.")
                self.isPlaying = false
                player?.pause()
                player?.seek(to: CMTime.zero, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }

    deinit {
        releaseResources()
    }
    
    init(frame: NSRect, config: ScreenConfiguration, screen: NSScreen) {
        super.init(frame: frame)
        setupPlayer(with: config)
        playScreen = screen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(with config: ScreenConfiguration) {
        if let url = config.contentUrl {
            let player = AVPlayer(url: url)
            self.player = player
            player.volume = config.volume
            player.isMuted = !config.isMainScreen
            // 暂时默认使用 Fill 填充方式, 其他方式保留
            self.videoGravity = .resizeAspectFill
            // setVideoFillMode(config.videoFillMode)
            startMonitoringNotification()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(name: .setWallpaperIsVisible, object: config.screenIdentifier, userInfo: ["isVisible": true])
                player.play()
            }
        }
    }

    private func setVideoFillMode(_ mode: VideoFillMode) {
        switch mode {
        case .fit:
            self.videoGravity = .resizeAspect
        case .fill:
            self.videoGravity = .resizeAspectFill
        case .stretch:
            self.videoGravity = .resize
        }
    }
}
