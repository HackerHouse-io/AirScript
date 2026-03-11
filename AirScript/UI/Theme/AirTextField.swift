import SwiftUI

struct AirTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AirScriptTheme.Spacing.xs) {
            Text(label.uppercased())
                .font(AirScriptTheme.fontBadge)
                .foregroundStyle(AirScriptTheme.textTertiary)
                .tracking(0.5)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(AirScriptTheme.Spacing.sm)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.sm, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AirScriptTheme.Radius.sm, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5))
        }
    }
}
