import SwiftUI

struct AnimatedGIF: View {
    private let animation: GIFAnimation?
    @State private var startDate = Date()
    
    init(data: Data) {
        self.animation = GIFAnimation(data: data)
    }
    
    var body: some View {
        Group {
            if let animation {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    Image(decorative: animation.frame(at: timeline.date, relativeTo: startDate), scale: 1)
                        .resizable()
                        .scaledToFit()
                }
            } else {
                Color.clear
            }
        }
        .onAppear {
            startDate = Date()
        }
    }
}
