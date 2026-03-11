import SwiftUI

struct SectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var trailing: Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AirScriptTheme.fontSectionHeader)
                    .foregroundStyle(AirScriptTheme.textSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(AirScriptTheme.fontSubheadline)
                        .foregroundStyle(AirScriptTheme.textTertiary)
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, AirScriptTheme.Spacing.lg)
        .padding(.top, AirScriptTheme.Spacing.sm)
        .padding(.bottom, AirScriptTheme.Spacing.xs)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
    }
}
