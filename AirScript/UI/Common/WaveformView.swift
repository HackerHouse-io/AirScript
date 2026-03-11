import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    let barCount: Int

    init(audioLevel: Float, barCount: Int = 20) {
        self.audioLevel = audioLevel
        self.barCount = barCount
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let barWidth = size.width / CGFloat(barCount * 2 - 1)
                let maxHeight = size.height

                for i in 0..<barCount {
                    let x = CGFloat(i) * barWidth * 2
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let phase = Double(i) * 0.2 + time * 3
                    let amplitude = CGFloat(audioLevel) * 10
                    let height = max(2, maxHeight * CGFloat(0.1 + amplitude * abs(sin(phase))))

                    let y = (maxHeight - height) / 2
                    let rect = CGRect(x: x, y: y, width: barWidth, height: height)
                    let path = RoundedRectangle(cornerRadius: barWidth / 2)
                        .path(in: rect)
                    context.fill(path, with: .color(AirScriptTheme.accent.opacity(0.7)))
                }
            }
        }
    }
}
