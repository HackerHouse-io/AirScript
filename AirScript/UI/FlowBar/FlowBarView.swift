import SwiftUI

enum FlowBarState: Equatable {
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

    private let cornerRadius = AirScriptTheme.Radius.xl

    var body: some View {
        VStack(spacing: AirScriptTheme.Spacing.md) {
            stateIconView

            if isActive {
                divider
            }

            if isRecording {
                SoundBarsView(
                    isAnimating: true,
                    barCount: 5,
                    color: stateColor
                )
                .frame(width: 26, height: 18)
            }

            if state == .processing {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(width: 18, height: 18)
                    .tint(.secondary)
            }

            if isRecording {
                Text(formatDuration(duration))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: Int(duration))
            }

            if !partialTranscript.isEmpty && state != .processing {
                Image(systemName: "text.bubble.fill")
                    .font(AirScriptTheme.fontCaption2)
                    .foregroundStyle(stateColor.opacity(0.7))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .background { backgroundView }
        .overlay { borderView }
        .fixedSize()
        .animation(AirScriptTheme.Anim.medium, value: state)
        .animation(AirScriptTheme.Anim.medium, value: partialTranscript.isEmpty)
    }

    // MARK: - Subviews

    private var stateIconView: some View {
        ZStack {
            Circle()
                .fill(stateColor.opacity(0.12))
                .frame(width: 32, height: 32)

            Image(systemName: stateIcon)
                .font(AirScriptTheme.fontSectionHeader)
                .foregroundStyle(stateColor)
        }
    }

    private var divider: some View {
        RoundedRectangle(cornerRadius: 0.5)
            .fill(.quaternary)
            .frame(width: 16, height: 1)
    }

    private var backgroundView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.regularMaterial)

            if isRecording {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(stateColor.opacity(0.05))
            }
        }
        .airShadow(.card)
    }

    private var borderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)

            if isRecording {
                PulsingBorderView(
                    color: stateColor,
                    isAnimating: true,
                    cornerRadius: cornerRadius
                )
            }
        }
    }

    // MARK: - State

    private var isRecording: Bool {
        state == .recordingPTT || state == .recordingHandsFree || state == .command
    }

    private var isActive: Bool {
        isRecording || state == .processing
    }

    private var stateColor: Color {
        switch state {
        case .recordingPTT: AirScriptTheme.accent
        case .recordingHandsFree: AirScriptTheme.statusListening
        case .command: AirScriptTheme.accent
        case .error: AirScriptTheme.statusWarning
        default: .secondary
        }
    }

    private var stateIcon: String {
        switch state {
        case .idle: "mic.fill"
        case .recordingPTT: "mic.fill"
        case .recordingHandsFree: "waveform"
        case .processing: "sparkles"
        case .command: "terminal.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
