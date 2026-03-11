import SwiftUI

struct StatusBadge: View {
    let text: String
    var color: Color = AirScriptTheme.accent
    var style: BadgeStyle = .default

    enum BadgeStyle { case `default`, mono, subtle }

    var body: some View {
        Group {
            switch style {
            case .default:
                Text(text)
                    .font(AirScriptTheme.fontBadge)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.18), in: Capsule())
            case .mono:
                Text(text.uppercased())
                    .font(AirScriptTheme.fontBadge)
                    .tracking(0.8)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.18), in: Capsule())
            case .subtle:
                Text(text)
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
    }
}
