import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case permissions
    case modelSelection
    case test
    case done
}

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: OnboardingStep = .welcome

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 4) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding()

            Divider()

            // Content
            Group {
                switch currentStep {
                case .welcome:
                    welcomeStep
                case .permissions:
                    PermissionStepView()
                        .environment(appState)
                case .modelSelection:
                    ModelSelectionStepView()
                        .environment(appState)
                case .test:
                    RecordingTestView()
                        .environment(appState)
                case .done:
                    doneStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Navigation
            HStack {
                if currentStep != .welcome {
                    Button("Back") {
                        if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                            currentStep = prev
                        }
                    }
                }
                Spacer()
                Button(currentStep == .done ? "Get Started" : "Continue") {
                    if currentStep == .done {
                        appState.hasCompletedOnboarding = true
                        dismiss()
                    } else if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                        currentStep = next
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("Welcome to AirScript")
                .font(.title)
            Text("100% local voice dictation for macOS.\nYour voice never leaves your computer.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var doneStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("You're all set!")
                .font(.title)
            VStack(alignment: .leading, spacing: 8) {
                hotkeyHint("fn (hold)", "Push-to-talk")
                hotkeyHint("fn (double-tap)", "Hands-free mode")
                hotkeyHint("Escape", "Cancel dictation")
                hotkeyHint("fn + Ctrl", "Command mode")
            }
            .padding()
            .background(.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }

    private func hotkeyHint(_ key: String, _ desc: String) -> some View {
        HStack {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(desc)
                .font(.subheadline)
        }
    }
}
