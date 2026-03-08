import SwiftUI
import SwiftData

struct StylePage: View {
    @Query private var styles: [AppStyle]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroBanner
                styleGrid
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            ensureStylesExist()
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Writing Style")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Set your tone per context. AirScript adjusts formatting and language to match — casual for messages, formal for emails, and everything in between.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "paintbrush.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.pink, Color.pink.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Style Grid

    private var styleGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(StyleCategory.allCases, id: \.self) { category in
                styleCategoryCard(for: category)
            }
        }
    }

    private func styleCategoryCard(for category: StyleCategory) -> some View {
        let style = styleForCategory(category)
        let currentPreset = style?.style ?? .casual

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryIcon(for: category))
                    .font(.title3)
                    .foregroundStyle(categoryColor(for: category))

                Text(categoryDisplayName(for: category))
                    .font(.headline)

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
                .font(.caption)
                .foregroundStyle(.secondary)
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

            // Preview
            Text(previewText(for: currentPreset))
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
                .lineLimit(1)
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private func categoryColor(for category: StyleCategory) -> Color {
        switch category {
        case .personalMessaging: .green
        case .workMessaging: .blue
        case .email: .orange
        case .codingChat: .purple
        case .notes: .yellow
        case .other: .gray
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
