//
//  PlayingViews.swift
//  codelume-app
//
//  Created by lyke on 2025/8/13.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PlayingView: View {
    @StateObject private var viewModel = ScreenPlaybackViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("屏幕管理")
                .font(.title)
                .fontWeight(.bold)

            // 屏幕列表
            VStack(alignment: .leading, spacing: 10) {
                Text("可用屏幕:")
                    .font(.headline)

                Picker("选择屏幕", selection: $viewModel.selectedScreen) {
                    ForEach(viewModel.screens, id: \.self) {
                        Text("\($0.localizedName) (\($0.frame.width)x\($0.frame.height))")
                    }
                }
                .onChange(of: viewModel.selectedScreen) { oldValue, newValue in
                    if let screen = newValue {
                        viewModel.loadScreenConfiguration(screen: screen)
                    }
                }
            }

            // 播放设置
            VStack(alignment: .leading, spacing: 10) {
                Text("播放设置:")
                    .font(.headline)

                // 播放类型
                HStack {
                    Text("播放类型:")
                        .frame(width: 100, alignment: .leading)
                    Picker("播放类型", selection: $viewModel.selectedPlaybackType) {
                        Text("视频").tag(PlaybackType.video)
                        Text("SpriteKit").tag(PlaybackType.sprite)
                        Text("SceneKit").tag(PlaybackType.scene)
                    }
                    .frame(width: 200)
                }

                // 视频文件路径
                if viewModel.selectedPlaybackType == .video {
                    HStack {
                        Text("文件路径:")
                            .frame(width: 100, alignment: .leading)
                        TextField("输入文件路径", text: $viewModel.contentPath)
                            .frame(width: 300)
                        Button("浏览") {
                            viewModel.selectFile()
                        }
                    }
                }

                // 音量控制
                HStack {
                    Text("音量:")
                        .frame(width: 100, alignment: .leading)
                    Slider(
                        value: $viewModel.volume,
                        in: 0...1,
                        step: 0.1
                    )
                    Text(String(format: "%.1f", viewModel.volume))
                        .frame(width: 40)
                }

                // 播放控制
                HStack {
                    Text("播放状态:")
                        .frame(width: 100, alignment: .leading)
                    Toggle("正在播放", isOn: $viewModel.isPlaying)
                }
            }

            // 更新按钮
            Button("更新配置") {
                viewModel.updateScreenConfiguration()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

#Preview {
    PlayingView()
}
