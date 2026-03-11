import SwiftUI
import SwiftData

struct AddCustomCommandSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var trigger = ""
    @State private var actionType: CustomCommandActionType = .openApp
    @State private var actionValue = ""

    var body: some View {
        AirSheet(title: "Add Custom Command") {
            VStack(spacing: 16) {
                AirTextField(label: "Trigger phrase", text: $trigger, placeholder: "e.g. open google")

                Picker("Action type", selection: $actionType) {
                    Text("Keystroke").tag(CustomCommandActionType.keystroke)
                    Text("Open App").tag(CustomCommandActionType.openApp)
                    Text("Open URL").tag(CustomCommandActionType.openURL)
                }

                AirTextField(label: valueLabel, text: $actionValue, placeholder: valuePlaceholder)

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
                    .tint(AirScriptTheme.accent)
                }
            }
            .padding()
        }
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
