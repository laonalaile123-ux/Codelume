//
//  WallpaperUtils.swift
//  CodeLume
//
//  Created by Lyke on 2025/3/20.
//

import AppKit
import AVFoundation
import Foundation
import ServiceManagement

func setFirstFrameAsWallpaper(videoURL: URL) -> Bool {
    let asset = AVAsset(url: videoURL)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    do {
        let cgImage = try imageGenerator.copyCGImage(
            at: CMTime(seconds: 0, preferredTimescale: 60), actualTime: nil)
        let image = NSImage(
            cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return setWallpaper(image: image, name: videoURL.deletingPathExtension().lastPathComponent)
    } catch {
        Logger.error("Error extracting first frame: \(error).")
        return false
    }
}

func setWallpaper(image: NSImage, name: String) -> Bool {
    let fileManager = FileManager.default
    guard let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        Logger.error("Cannot get document directory.")
        return false
    }
    let imageDir = docDir.appendingPathComponent("currentwallpaper")
    let imageURL = imageDir.appendingPathComponent("\(name).jpg")
    
    do {
        if !fileManager.fileExists(atPath: imageDir.path) {
            try fileManager.createDirectory(at: imageDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        guard let imageData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: imageData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) else {
            Logger.error("Failed to generate jpeg data.")
            return false
        }
        try jpegData.write(to: imageURL)
        
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true,
        ]
        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            try? workspace.setDesktopImageURL(imageURL, for: screen, options: options)
        }
        
        let files = try fileManager.contentsOfDirectory(at: imageDir, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "jpg" && file != imageURL {
            try fileManager.removeItem(at: file)
        }
    } catch {
        Logger.error("Error setting wallpaper: \(error).")
        return false
    }
    
    Logger.info("Set wallpaper success for \(imageURL).")
    return true
}
