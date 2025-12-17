
//  WallpaperHubViews.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/16.


import SwiftUI

struct WallpaperHubView: View {
    var body: some View {
        Text("Coming soon.")
    }
}

struct WallpaperHubViews1: View {
    @State private var wallpapers: [WallpaperTable] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading wallpapers...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                        Button("Retry") {
                            loadWallpapers()
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                            ForEach(wallpapers) { wallpaper in
                                WallpaperCard(wallpaper: wallpaper)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Wallpaper Hub")
            .task {
                loadWallpapers()
            }
        }
    }
    
    private func loadWallpapers() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                defer {
                    isLoading = false
                }
                wallpapers = try await SupabaseManager.shared.getAllWallpapers()
            } catch {
                errorMessage = error.localizedDescription
                Logger.error("Failed to load wallpapers: \(error)")
            }
        }
    }
}

struct WallpaperCard: View {
    let wallpaper: WallpaperTable
    
    var body: some View {
        VStack(alignment: .leading) {
          AsyncImage(url: SupabaseManager.shared.getPreviewImageUrl(wallpaperBundle: wallpaper.fileName)) { phase in
              switch phase {
              case .empty:
                  ProgressView()
                      .frame(width: 200, height: 150)
              case .success(let image):
                  image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                      .frame(width: 200, height: 150)
                      .clipped()
              case .failure:
                  Image(systemName: "photo")
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                      .frame(width: 200, height: 150)
                      .clipped()
                      .foregroundColor(.gray)
              @unknown default:
                  EmptyView()
              }
          }
            
            Text(wallpaper.fileName)
                .font(.headline)
                .padding(.top, 8)
            
//            if let description = wallpaper.description {
//                Text(description)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .lineLimit(2)
//            }
            
            Button("Download") {
//                downloadWallpaper(wallpaper)
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .frame(width: 200)
        .padding()
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
//    private func downloadWallpaper(_ wallpaper: SupabaseManager.WallpaperBundle) {
//        Task {
//            do {
//                guard let url = URL(string: wallpaper.bundleUrl) else {
//                    throw URLError(.badURL)
//                }
//                
//                let (data, response) = try await URLSession.shared.data(from: url)
//                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                    throw URLError(.badServerResponse)
//                }
//                
//                // 保存文件到临时目录
//                let tempDir = FileManager.default.temporaryDirectory
//                let tempFileURL = tempDir.appendingPathComponent("\(wallpaper.name).bundle.zip")
//                try data.write(to: tempFileURL)
//                
//                // 这里可以添加解压和安装逻辑
//                Logger.info("Wallpaper downloaded successfully: \(wallpaper.name)")
//                
//            } catch {
//                Logger.error("Failed to download wallpaper: \(error)")
//            }
//        }
//    }
}

#Preview {
    WallpaperHubView()
}
