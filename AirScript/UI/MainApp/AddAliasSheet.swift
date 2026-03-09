import SwiftUI
import SwiftData

struct AddAliasSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var spokenName = ""
    @State private var appName = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add App Alias")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Say")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. my editor", text: $spokenName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Opens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Cursor", text: $appName)
                        .textFieldStyle(.roundedBorder)
                }
            }

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
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
