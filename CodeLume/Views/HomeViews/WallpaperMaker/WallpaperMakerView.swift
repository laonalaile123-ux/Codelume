//
//  WallpaperMakerView.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/17.
//

import SwiftUI

struct WallpaperMakerView: View {
    @State var bundleName: String = ""
    @State var wallpaperName: String = ""
    @State var videoURL: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("资源包基本信息")
            Form {
                
                TextField("Bundle Name:", text: $bundleName)
                TextField("Wallpaper Name:", text: $wallpaperName)
                
            }
            Divider()
            Form {
                HStack(){
                    TextField("Video URL:", text: $videoURL)
                    Button("Select Video File") {
                        
                    }
                }
                
                
            }
            Divider()
        }
        .padding(10)
        
        .padding(10)
    }
}

#Preview {
    WallpaperMakerView()
}
