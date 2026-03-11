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
            // Progress dots
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue
                              ? AirScriptTheme.accent
                              : Color(nsColor: .separatorColor))
                        .frame(width: 8, height: 8)
                }
            }
            .padding()

            Divider()

            // Content with transitions
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
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            Divider()

            // Navigation
            HStack {
                if currentStep != .welcome {
                    Button("Back") {
                        if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                            withAnimation {
                                currentStep = prev
                            }
                        }
                    }
                }
                Spacer()
                Button(currentStep == .done ? "Get Started" : "Continue") {
                    if currentStep == .done {
                        appState.hasCompletedOnboarding = true
                        dismiss()
                    } else if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                        withAnimation {
                            currentStep = next
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AirScriptTheme.accent)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AirScriptTheme.accentWash)
                    .frame(width: 100, height: 100)
                Image(systemName: "waveform")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AirScriptTheme.accent)
            }
            Text("Welcome to AirScript")
                .font(AirScriptTheme.fontHero)
            Text("100% local voice dictation for macOS.\nYour voice never leaves your computer.")
                .multilineTextAlignment(.center)
                .foregroundStyle(AirScriptTheme.textSecondary)
        }
        .padding()
    }

    private var doneStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AirScriptTheme.statusSuccess.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AirScriptTheme.statusSuccess)
            }
            Text("You're all set!")
                .font(AirScriptTheme.fontHero)
            VStack(alignment: .leading, spacing: 8) {
                hotkeyHint("fn (hold)", "Push-to-talk")
                hotkeyHint("fn (double-tap)", "Hands-free mode")
                hotkeyHint("Escape", "Cancel dictation")
                hotkeyHint("fn + Ctrl", "Command mode")
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.md))
        }
        .padding()
    }

    private func hotkeyHint(_ key: String, _ desc: String) -> some View {
        HStack {
            Text(key)
                .font(AirScriptTheme.fontMono)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4))
            Text(desc)
                .font(.subheadline)
        }
    }
}
