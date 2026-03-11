import SwiftUI

struct PageHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AirScriptTheme.accent)
                .frame(width: 32, height: 4)
            Text(title).font(AirScriptTheme.fontHero)
            if let subtitle {
                Text(subtitle)
                    .font(AirScriptTheme.fontSubtitle)
                    .foregroundStyle(AirScriptTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AirScriptTheme.Spacing.lg)
        .padding(.bottom, AirScriptTheme.Spacing.xs)
    }
}
