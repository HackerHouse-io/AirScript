import SwiftUI
import SwiftData

struct AddAliasSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var spokenName = ""
    @State private var appName = ""

    var body: some View {
        AirSheet(title: "Add App Alias") {
            VStack(spacing: 16) {
                AirTextField(label: "Say", text: $spokenName, placeholder: "e.g. my editor")
                AirTextField(label: "Opens", text: $appName, placeholder: "e.g. Cursor")

                HStack {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("Add") {
                        let alias = CustomAppAlias(
                            spokenName: spokenName.lowercased(),
                            appName: appName
                        )
                        modelContext.insert(alias)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(spokenName.isEmpty || appName.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(AirScriptTheme.accent)
                }
            }
            .padding()
        }
        .frame(width: 360)
    }
}
