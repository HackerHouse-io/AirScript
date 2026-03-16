import SwiftUI

struct HoverRow<Content: View, Trailing: View>: View {
    @State private var isHovered = false
    @ViewBuilder var content: () -> Content
    @ViewBuilder var trailing: (Bool) -> Trailing

    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder trailing: @escaping (Bool) -> Trailing) {
        self.content = content
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 0) {
            content()
            trailing(isHovered)
        }
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

extension HoverRow where Trailing == EmptyView {
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.trailing = { _ in EmptyView() }
    }
}
