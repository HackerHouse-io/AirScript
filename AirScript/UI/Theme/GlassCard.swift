import SwiftUI

struct GlassCard<Content: View>: View {
    var padding: CGFloat = AirScriptTheme.Spacing.lg
    var accentBorder: Bool = false
    var hoverLift: Bool = false
    @State private var isHovered = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AirScriptTheme.Radius.md, style: .continuous)
                    .strokeBorder(accentBorder ? AirScriptTheme.accentSubtle : Color(nsColor: .separatorColor).opacity(0.3),
                                  lineWidth: accentBorder ? 1.5 : 0.5)
            )
            .airShadow(isHovered && hoverLift ? .cardHover : .card)
            .offset(y: isHovered && hoverLift ? -1 : 0)
            .scaleEffect(isHovered && hoverLift ? 1.01 : 1.0)
            .onHover { hovering in
                if hoverLift { isHovered = hovering }
            }
            .animation(AirScriptTheme.Anim.fast, value: isHovered)
    }
}
