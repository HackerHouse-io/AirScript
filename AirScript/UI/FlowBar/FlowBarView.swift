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
                    .foregroundStyle(.primary.opacity(0.8))
            }

            if !partialTranscript.isEmpty && state != .processing {
                Text(partialTranscript)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 200)
            }

            if state == .command {
                Image(systemName: "terminal.fill")
                    .font(.caption)
                    .foregroundStyle(AirScriptTheme.accent)
                Text("Command")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thickMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
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
        case .recordingPTT: AirScriptTheme.statusError
        case .recordingHandsFree: .primary
        case .command: AirScriptTheme.accent
        default: .gray
        }
    }

    private var borderColor: Color {
        switch state {
        case .recordingPTT: AirScriptTheme.statusError
        case .recordingHandsFree: .primary
        case .command: AirScriptTheme.accent
        case .error: AirScriptTheme.accentWarm
        default: .clear
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
