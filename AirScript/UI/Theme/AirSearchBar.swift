import SwiftUI

struct AirSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isFocused ? AirScriptTheme.accent : .secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(AirScriptTheme.Spacing.sm)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.sm, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AirScriptTheme.Radius.sm, style: .continuous)
            .strokeBorder(isFocused ? AirScriptTheme.accentSubtle : .clear, lineWidth: 1))
    }
}
