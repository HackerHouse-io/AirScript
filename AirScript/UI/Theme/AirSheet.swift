import SwiftUI

struct AirSheet<Content: View>: View {
    let title: String
    var onDismiss: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title).font(AirScriptTheme.fontSectionTitle)
                Spacer()
                if let onDismiss {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
            }
            .padding()
            .background(.regularMaterial)

            Divider()

            content()
        }
    }
}
