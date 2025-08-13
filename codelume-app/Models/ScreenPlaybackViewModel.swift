import AppKit

class ScreenPlaybackViewModel: ObservableObject {
    @Published var screens: [NSScreen] = []
    @Published var selectedScreen: NSScreen?
    @Published var selectedPlaybackType: PlaybackType = .video
    @Published var contentPath: String = ""
    @Published var volume: Float = 1.0
    @Published var isPlaying: Bool = false
    
    // 单例实例
    static let shared = ScreenPlaybackViewModel()
    
    private init() {
        // 初始化屏幕列表
        updateScreens()
        // 监听屏幕变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateScreens),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc func updateScreens() {
        screens = NSScreen.screens
        // 如果没有选中屏幕，默认选中第一个
        if selectedScreen == nil && !screens.isEmpty {
            selectedScreen = screens.first
            // 加载选中屏幕的配置
            loadScreenConfiguration(screen: selectedScreen!)
        }
    }
    
    // 加载屏幕配置
    func loadScreenConfiguration(screen: NSScreen) {
        // 从WindowController获取配置
        if let windowController = NSApplication.shared.delegate?.windowController {
            let screenIdentifier = screen.identifier
            if let config = windowController.screenConfigurations[screenIdentifier] {
                selectedPlaybackType = config.playbackType
                contentPath = config.contentPath
                volume = config.volume
                isPlaying = config.isPlaying
            } else {
                // 默认配置
                selectedPlaybackType = .video
                contentPath = ""
                volume = 1.0
                isPlaying = false
            }
        }
    }
    
    // 更新屏幕配置
    func updateScreenConfiguration() {
        guard let screen = selectedScreen else { return }
        
        if let windowController = NSApplication.shared.delegate?.windowController {
            // 更新播放类型和内容路径
//            windowController.updateScreenConfiguration(
//                screen,
//                playbackType: selectedPlaybackType,
//                contentPath: contentPath,
//                volume: volume,
//                isPlaying: isPlaying
//            )
        }
    }
    
    // 选择文件
    func selectFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie] // 视频文件类型
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                contentPath = url.path
            }
        }
    }
}
