import SwiftUI
import SwiftData

struct AddCustomCommandSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var trigger = ""
    @State private var actionType: CustomCommandActionType = .openApp
    @State private var actionValue = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Command")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trigger phrase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. open google", text: $trigger)
                        .textFieldStyle(.roundedBorder)
                }

                Picker("Action type", selection: $actionType) {
                    Text("Keystroke").tag(CustomCommandActionType.keystroke)
                    Text("Open App").tag(CustomCommandActionType.openApp)
                    Text("Open URL").tag(CustomCommandActionType.openURL)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(valueLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField(valuePlaceholder, text: $actionValue)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    let command = CustomVoiceCommand(
                        trigger: trigger.lowercased(),
                        actionType: actionType,
                        actionValue: actionValue
                    )
                    modelContext.insert(command)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trigger.isEmpty || actionValue.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private var valueLabel: String {
        switch actionType {
        case .keystroke: "Keystroke (keyCode:flags)"
        case .openApp: "App name"
        case .openURL: "URL"
        }
    }

    private var valuePlaceholder: String {
        switch actionType {
        case .keystroke: "e.g. 36:cmd (Enter with Cmd)"
        case .openApp: "e.g. Safari"
        case .openURL: "e.g. https://google.com"
        }
    }
}
