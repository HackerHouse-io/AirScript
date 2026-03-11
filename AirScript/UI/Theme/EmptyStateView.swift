import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AirScriptTheme.accentWash)
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(AirScriptTheme.accentMuted)
            }
            .accessibilityHidden(true)
            Text(title)
                .font(AirScriptTheme.fontSectionTitle)
                .foregroundStyle(AirScriptTheme.textSecondary)
            if let subtitle {
                Text(subtitle)
                    .font(AirScriptTheme.fontSubtitle)
                    .foregroundStyle(AirScriptTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(AirScriptTheme.accent)
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
