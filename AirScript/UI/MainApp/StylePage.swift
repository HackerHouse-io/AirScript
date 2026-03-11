import SwiftUI
import SwiftData

struct StylePage: View {
    @Query private var styles: [AppStyle]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PageHeader(title: "Writing Style")

                SectionHeader(title: "Style Presets", subtitle: "Customize voice output per app category")

                styleGrid
            }
            .padding(.bottom, 8)
        }
        .onAppear {
            ensureStylesExist()
        }
    }

    // MARK: - Style Grid

    private var styleGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(Array(StyleCategory.allCases.enumerated()), id: \.element) { index, category in
                styleCategoryCard(for: category)
                    .staggeredAppear(index: index)
            }
        }
        .padding(.horizontal)
    }

    private func styleCategoryCard(for category: StyleCategory) -> some View {
        let style = styleForCategory(category)
        let currentPreset = style?.style ?? .casual

        return GlassCard(hoverLift: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: categoryIcon(for: category))
                        .font(.title3)
                        .foregroundStyle(AirScriptTheme.accent)

                    Text(categoryDisplayName(for: category))
                        .font(AirScriptTheme.fontBodyMedium)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { style?.isEnabled ?? true },
                        set: { newValue in
                            ensureStyle(for: category).isEnabled = newValue
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                Text(categoryDescription(for: category))
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.textSecondary)
                    .lineLimit(2)

                Picker("", selection: Binding(
                    get: { currentPreset },
                    set: { newPreset in
                        ensureStyle(for: category).style = newPreset
                    }
                )) {
                    ForEach(StylePreset.allCases, id: \.self) { preset in
                        Text(presetDisplayName(for: preset)).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                Text(previewText(for: currentPreset))
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.textTertiary)
                    .italic()
                    .lineLimit(1)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Helpers

    private func styleForCategory(_ category: StyleCategory) -> AppStyle? {
        styles.first { $0.category == category }
    }

    @discardableResult
    private func ensureStyle(for category: StyleCategory) -> AppStyle {
        if let existing = styleForCategory(category) {
            return existing
        }
        let style = AppStyle(category: category, style: .casual)
        modelContext.insert(style)
        return style
    }

    private func ensureStylesExist() {
        for category in StyleCategory.allCases {
            ensureStyle(for: category)
        }
    }

    private func categoryIcon(for category: StyleCategory) -> String {
        switch category {
        case .personalMessaging: "message.fill"
        case .workMessaging: "bubble.left.and.bubble.right.fill"
        case .email: "envelope.fill"
        case .codingChat: "chevron.left.forwardslash.chevron.right"
        case .notes: "note.text"
        case .other: "ellipsis.circle.fill"
        }
    }

    private func categoryDisplayName(for category: StyleCategory) -> String {
        switch category {
        case .personalMessaging: "Personal Messages"
        case .workMessaging: "Work Messages"
        case .email: "Email"
        case .codingChat: "Coding Chat"
        case .notes: "Notes"
        case .other: "Other Apps"
        }
    }

    private func categoryDescription(for category: StyleCategory) -> String {
        switch category {
        case .personalMessaging: "iMessage, WhatsApp, Telegram"
        case .workMessaging: "Slack, Teams, Discord"
        case .email: "Mail, Gmail, Outlook"
        case .codingChat: "Cursor, VS Code, GitHub"
        case .notes: "Notes, Notion, Obsidian"
        case .other: "All other applications"
        }
    }

    private func presetDisplayName(for preset: StylePreset) -> String {
        switch preset {
        case .veryCasual: "Chill"
        case .casual: "Casual"
        case .excited: "Lively"
        case .formal: "Formal"
        }
    }

    private func previewText(for preset: StylePreset) -> String {
        switch preset {
        case .veryCasual: "\"hey yeah sounds good lmk when ur free\""
        case .casual: "\"Hey, sounds good! Let me know when you're free.\""
        case .excited: "\"That sounds amazing! Can't wait - let me know!\""
        case .formal: "\"That sounds great. Please let me know your availability.\""
        }
    }
}
