import SwiftUI
import ImageIO

struct GIFAnimation {
    struct Frame {
        let image: CGImage
        let duration: TimeInterval
    }
    
    let frames: [Frame]
    let totalDuration: TimeInterval
    
    init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else {
            return nil
        }
        
        var decodedFrames: [Frame] = []
        var durationSum: TimeInterval = 0
        
        for index in 0..<frameCount {
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            
            let frameDuration = Self.frameDuration(for: source, at: index)
            decodedFrames.append(Frame(image: image, duration: frameDuration))
            durationSum += frameDuration
        }
        
        guard !decodedFrames.isEmpty else {
            return nil
        }
        
        self.frames = decodedFrames
        self.totalDuration = max(durationSum, 0.1)
    }
    
    func frame(at date: Date, relativeTo startDate: Date) -> CGImage {
        let elapsed = date.timeIntervalSince(startDate).truncatingRemainder(dividingBy: totalDuration)
        var accumulated: TimeInterval = 0
        
        for frame in frames {
            accumulated += frame.duration
            if elapsed < accumulated {
                return frame.image
            }
        }
        
        return frames[frames.count - 1].image
    }
    
    private static func frameDuration(for source: CGImageSource, at index: Int) -> TimeInterval {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.1
        }
        
        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let delay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
        let duration = unclampedDelay ?? delay ?? 0.1
        
        return duration < 0.011 ? 0.1 : duration
    }
}
