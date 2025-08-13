//
//  SettingsView.swift
//  CodeLume
//
//  Created by Lyke on 2025/3/13.
//
//
//import SwiftUI
//
//struct SettingsView: View {
//    @State private var selectedTab = 1
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            GeneralSettingsView().tabItem {
//                Label("General Settings", systemImage: "gear")
//            }.tag(1)
//            PlaybackSettingsView().tabItem {
//                Label("Playback Settings", systemImage: "play.circle")
//            }.tag(2)
//        }
//        .frame(width: 500, height: 400)
//    }
//}
//
//#Preview {
//    SettingsView()
//}
