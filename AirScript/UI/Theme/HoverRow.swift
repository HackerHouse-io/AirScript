import SwiftUI

struct HoverRow<Content: View>: View {
    @State private var isHovered = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, AirScriptTheme.Spacing.md)
            .padding(.vertical, AirScriptTheme.Spacing.sm)
            .background(
                isHovered ? AirScriptTheme.surfaceHover : .clear,
                in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.sm, style: .continuous)
            )
            .onHover { isHovered = $0 }
            .animation(AirScriptTheme.Anim.fast, value: isHovered)
    }
}
