import Foundation
import AppKit
import Foundation

class WindowController: NSObject {
    // 存储所有屏幕上的窗口
    var windows: [NSScreen: NSWindow] = [:]
    // 存储所有屏幕的配置
    var screenConfigurations: [String: ScreenConfiguration] = [:]
    // 存储每个屏幕的播放视图
    var playbackViews: [String: NSView] = [:]

    override init() {
        super.init()
        // 加载保存的配置
        loadConfigurations()
        // 为所有屏幕创建窗口
        createWindowsForAllScreens()
        // 监听屏幕变化
        startMonitoringScreenChanges()
    }

    // 为所有屏幕创建窗口
    func createWindowsForAllScreens() {
        // 移除所有现有窗口
        for window in windows.values {
            window.close()
        }
        windows.removeAll()

        // 为每个屏幕创建一个窗口
        for screen in NSScreen.screens {
            createWindowForScreen(screen)
        }
    }

    // 加载配置
    func loadConfigurations() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "screenConfigurations") {
            do {
                let decoder = JSONDecoder()
                screenConfigurations = try decoder.decode([String: ScreenConfiguration].self, from: data)
            } catch {
                print("加载配置失败: \(error)")
            }
        }
    }
    
    // 保存配置
    func saveConfigurations() {
        let defaults = UserDefaults.standard
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(screenConfigurations)
            defaults.set(data, forKey: "screenConfigurations")
        } catch {
            print("保存配置失败: \(error)")
        }
    }
    
    // 创建播放视图
    func createPlaybackView(for screen: NSScreen) -> NSView {
        let screenIdentifier = screen.identifier
        let config = screenConfigurations[screenIdentifier] ?? ScreenConfiguration(screen: screen)
        let viewFrame = screen.frame
        
        switch config.playbackType {
        case .video:
            return VideoPlaybackView(frame: viewFrame, config: config)
        case .spriteKit:
            return SpriteKitPlaybackView(frame: viewFrame)
        case .sceneKit:
            return SceneKitPlaybackView(frame: viewFrame)
        }
    }
    
    // 更新屏幕配置
    func updateScreenConfiguration(_ screen: NSScreen, playbackType: PlaybackType, contentPath: String = "") {
        let screenIdentifier = screen.identifier
        
        // 更新配置
        if var config = screenConfigurations[screenIdentifier] {
            config.playbackType = playbackType
            config.contentPath = contentPath
            screenConfigurations[screenIdentifier] = config
        } else {
            screenConfigurations[screenIdentifier] = ScreenConfiguration(screen: screen, playbackType: playbackType, contentPath: contentPath)
        }
        
        // 保存配置
        saveConfigurations()
        
        // 更新视图
        if let window = windows[screen] {
            // 移除旧的播放视图
            if let oldView = playbackViews[screenIdentifier] {
                oldView.removeFromSuperview()
            }
            
            // 创建新的播放视图
            let newView = createPlaybackView(for: screen)
            playbackViews[screenIdentifier] = newView
            window.contentView = newView
        }
    }
    
    // 为特定屏幕创建窗口
    func createWindowForScreen(_ screen: NSScreen) {
        let screenFrame = screen.frame
        let screenIdentifier = screen.identifier

        // 创建内容视图容器
        let contentView = NSView(frame: screenFrame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.cgColor

        // 创建播放视图
        let playbackView = createPlaybackView(for: screen)
        playbackViews[screenIdentifier] = playbackView
        contentView.addSubview(playbackView)

        // 添加控制按钮容器
        let controlView = NSView(frame: NSRect(x: 0, y: 0, width: screenFrame.width, height: 50))
        controlView.wantsLayer = true
        controlView.layer?.backgroundColor = NSColor(white: 0, alpha: 0.5).cgColor
        contentView.addSubview(controlView)

        // 添加屏幕信息标签
        let label = NSTextField(frame: NSRect(x: 20, y: 10, width: 200, height: 30))
        label.stringValue = "屏幕: \(screen.localizedName)"
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.textColor = NSColor.white
        label.font = NSFont.systemFont(ofSize: 14)
        controlView.addSubview(label)

        // 添加视频播放按钮
        let videoButton = NSButton(frame: NSRect(x: 240, y: 10, width: 80, height: 30))
        videoButton.title = "视频"
        videoButton.target = self
        videoButton.action = #selector(switchToVideo(_:))
        videoButton.tag = Int(screenIdentifier) ?? 0
        controlView.addSubview(videoButton)

        // 添加SpriteKit按钮
        let spriteButton = NSButton(frame: NSRect(x: 330, y: 10, width: 80, height: 30))
        spriteButton.title = "SpriteKit"
        spriteButton.target = self
        spriteButton.action = #selector(switchToSpriteKit(_:))
        spriteButton.tag = Int(screenIdentifier) ?? 0
        controlView.addSubview(spriteButton)

        // 添加SceneKit按钮
        let sceneButton = NSButton(frame: NSRect(x: 420, y: 10, width: 80, height: 30))
        sceneButton.title = "SceneKit"
        sceneButton.target = self
        sceneButton.action = #selector(switchToSceneKit(_:))
        sceneButton.tag = Int(screenIdentifier) ?? 0
        controlView.addSubview(sceneButton)

        // 创建窗口
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .utilityWindow],
            backing: .buffered,
            defer: false,
            screen: screen // 指定窗口显示在哪个屏幕
        )

        // 确保窗口正确定位在屏幕上
        window.setFrameOrigin(screenFrame.origin)

        window.contentView = contentView
       window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = false // 允许鼠标事件
        window.makeKeyAndOrderFront(nil)

        // 存储窗口
        windows[screen] = window
    }

    // 开始监听屏幕变化
    func startMonitoringScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // 处理屏幕变化
    @objc func handleScreenChange() {
        // 重新为所有屏幕创建窗口
        createWindowsForAllScreens()
    }

    // 切换到视频播放
    @objc func switchToVideo(_ sender: NSButton) {
        let screenIdentifier = String(sender.tag)
        // 找到对应的屏幕
        guard let screen = NSScreen.screens.first(where: { 
            $0.identifier == screenIdentifier
        }) else { return }
        
        // 创建文件选择器
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["mp4", "mov", "m4v", "avi", "mkv"]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { [weak self] result in
            guard let self = self, result == .OK, let url = openPanel.url else { return }
            
            // 更新屏幕配置
            self.updateScreenConfiguration(screen, playbackType: .video, contentPath: url.path)
        }
    }
    
    // 切换到SpriteKit
    @objc func switchToSpriteKit(_ sender: NSButton) {
        let screenIdentifier = String(sender.tag)
        // 找到对应的屏幕
        if let screen = NSScreen.screens.first(where: { 
            $0.identifier == screenIdentifier
        }) {
            updateScreenConfiguration(screen, playbackType: .spriteKit)
        }
    }
    
    // 切换到SceneKit
    @objc func switchToSceneKit(_ sender: NSButton) {
        let screenIdentifier = String(sender.tag)
        // 找到对应的屏幕
        if let screen = NSScreen.screens.first(where: { 
            $0.identifier == screenIdentifier
        }) {
            updateScreenConfiguration(screen, playbackType: .sceneKit)
        }
    }

    // 清理资源
    deinit {
        NotificationCenter.default.removeObserver(self)
        for window in windows.values {
            window.close()
        }
    }
}
