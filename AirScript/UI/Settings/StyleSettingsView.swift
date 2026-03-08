import SwiftUI
import SwiftData

struct StyleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var styles: [AppStyle]

    var body: some View {
        Form {
            ForEach(StyleCategory.allCases, id: \.self) { category in
                Section(categoryName(category)) {
                    let style = styles.first(where: { $0.category == category })

                    Picker("Style", selection: Binding(
                        get: { style?.style ?? .casual },
                        set: { newPreset in
                            if let existing = style {
                                existing.style = newPreset
                            } else {
                                let newStyle = AppStyle(category: category, style: newPreset)
                                modelContext.insert(newStyle)
                            }
                        }
                    )) {
                        ForEach(StylePreset.allCases, id: \.self) { preset in
                            Text(presetName(preset)).tag(preset)
                        }
                    }

                    if let style {
                        Toggle("Enabled", isOn: Binding(
                            get: { style.isEnabled },
                            set: { style.isEnabled = $0 }
                        ))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func categoryName(_ category: StyleCategory) -> String {
        switch category {
        case .personalMessaging: "Personal Messaging"
        case .workMessaging: "Work Messaging"
        case .email: "Email"
        case .codingChat: "Coding Chat"
        case .notes: "Notes"
        case .other: "Other"
        }
    }

    private func presetName(_ preset: StylePreset) -> String {
        switch preset {
        case .veryCasual: "Very Casual"
        case .casual: "Casual"
        case .excited: "Excited"
        case .formal: "Formal"
        }
    }
}
