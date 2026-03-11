import SwiftUI

struct AirScriptTheme {
    // MARK: - Brand Accent (5-variant palette)
    static let accent = Color(red: 0.388, green: 0.400, blue: 0.945)     // #6366F1 indigo (matches AccentColor asset)
    static let accentMuted = accent.opacity(0.7)                           // secondary emphasis
    static let accentSubtle = accent.opacity(0.4)                          // tertiary/borders
    static let accentWash = accent.opacity(0.08)                           // hover/surface tints
    static let accentBright = Color(red: 0.50, green: 0.52, blue: 1.0)    // highlights/gradients

    // MARK: - Semantic Accents
    static let accentWarm = Color.orange
    static let statusSuccess = Color.green
    static let statusError = Color.red

    // MARK: - Text (system adaptive)
    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)

    // MARK: - Backgrounds (system adaptive)
    static let backgroundPrimary = Color(nsColor: .windowBackgroundColor)
    static let backgroundSecondary = Color(nsColor: .controlBackgroundColor)
    static let backgroundElevated = Color(nsColor: .underPageBackgroundColor)

    // MARK: - Surfaces
    static let surfaceOverlay = Color(nsColor: .controlBackgroundColor)
    static let surfaceHover = accent.opacity(0.08)

    // MARK: - Typography (hero → section → body → caption hierarchy)
    static let fontHero: Font = .system(size: 28, weight: .bold, design: .rounded)
    static let fontSectionTitle: Font = .system(size: 17, weight: .semibold)
    static let fontSubtitle: Font = .system(size: 14)
    static let fontSectionHeader: Font = .system(size: 13, weight: .semibold)
    static let fontBodyPrimary: Font = .system(size: 13)
    static let fontBodyMedium: Font = .system(size: 13, weight: .medium)
    static let fontSubheadline: Font = .system(size: 12)
    static let fontCaption: Font = .system(size: 11)
    static let fontCaption2: Font = .system(size: 10)
    static let fontBadge: Font = .system(size: 10, weight: .semibold, design: .monospaced)
    static let fontStatValue: Font = .system(size: 24, weight: .bold, design: .rounded)
    static let fontStatLabel: Font = .system(size: 12, weight: .medium)
    static let fontMono: Font = .system(size: 11, design: .monospaced)

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 40
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
    }

    // MARK: - Animations
    enum Anim {
        static let fast: Animation = .easeInOut(duration: 0.15)
        static let medium: Animation = .easeInOut(duration: 0.25)
    }
}

// MARK: - Shadow Presets

struct AirShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    static let card = AirShadowStyle(color: .black.opacity(0.08), radius: 8, y: 2)
    static let cardHover = AirShadowStyle(color: .black.opacity(0.15), radius: 16, y: 6)
}

extension View {
    func airShadow(_ style: AirShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }
}
