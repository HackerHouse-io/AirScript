import SwiftUI

struct HotkeySettingsView: View {
    var body: some View {
        Form {
            Section("Dictation") {
                HStack {
                    Text("Push-to-Talk")
                    Spacer()
                    Text("fn (hold)")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack {
                    Text("Hands-Free Toggle")
                    Spacer()
                    Text("fn (double-tap)")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                HStack {
                    Text("Cancel")
                    Spacer()
                    Text("Escape")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Section("Command Mode") {
                HStack {
                    Text("Text Transform")
                    Spacer()
                    Text("fn + Ctrl")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Section {
                Text("Custom hotkey configuration coming in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
