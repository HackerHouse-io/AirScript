import SwiftUI

struct SoundBarsView: View {
    let isAnimating: Bool
    let barCount: Int
    let color: Color

    init(isAnimating: Bool, barCount: Int = 5, color: Color = .white) {
        self.isAnimating = isAnimating
        self.barCount = barCount
        self.color = color
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let barWidth = size.width / CGFloat(barCount * 2 - 1)
                let maxHeight = size.height

                for i in 0..<barCount {
                    let x = CGFloat(i) * barWidth * 2
                    let height: CGFloat

                    if isAnimating {
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let phase = Double(i) * 0.3 + time * 4
                        height = maxHeight * CGFloat(0.2 + 0.8 * abs(sin(phase)))
                    } else {
                        height = maxHeight * 0.15
                    }

                    let y = (maxHeight - height) / 2
                    let rect = CGRect(x: x, y: y, width: barWidth, height: height)
                    let path = RoundedRectangle(cornerRadius: barWidth / 2)
                        .path(in: rect)
                    context.fill(path, with: .color(color))
                }
            }
        }
    }
}

struct PulsingBorderView: View {
    let color: Color
    let isAnimating: Bool
    var cornerRadius: CGFloat = 20

    @State private var opacity: Double = 0.15

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(color, lineWidth: 1.5)
            .opacity(isAnimating ? opacity : 0)
            .onAppear {
                if isAnimating {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        opacity = 0.5
                    }
                }
            }
    }
}
