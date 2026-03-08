import SwiftUI

enum FlowBarState {
    case idle
    case recordingPTT
    case recordingHandsFree
    case processing
    case command
    case error
}

struct FlowBarView: View {
    let state: FlowBarState
    let audioLevel: Float
    let duration: TimeInterval
    let partialTranscript: String

    var body: some View {
        HStack(spacing: 10) {
            SoundBarsView(
                isAnimating: isRecording,
                barCount: 5,
                color: barsColor
            )
            .frame(width: 30, height: 20)

            if state == .processing {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }

            if isRecording {
                Text(formatDuration(duration))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
            }

            if !partialTranscript.isEmpty && state != .processing {
                Text(partialTranscript)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 200)
            }

            if state == .command {
                Text("Command")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            PulsingBorderView(
                color: borderColor,
                isAnimating: isRecording
            )
            .clipShape(Capsule())
        )
    }

    private var isRecording: Bool {
        state == .recordingPTT || state == .recordingHandsFree || state == .command
    }

    private var barsColor: Color {
        switch state {
        case .recordingPTT: .red
        case .recordingHandsFree: .white
        case .command: .blue
        default: .gray
        }
    }

    private var borderColor: Color {
        switch state {
        case .recordingPTT: .red
        case .recordingHandsFree: .white
        case .command: .blue
        case .error: .orange
        default: .clear
        }
    }

    private var backgroundColor: Color {
        Color.black.opacity(0.85)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
