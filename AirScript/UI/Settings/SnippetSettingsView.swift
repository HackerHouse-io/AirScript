import SwiftUI
import SwiftData

struct SnippetSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Snippet.trigger) private var snippets: [Snippet]
    @State private var newTrigger = ""
    @State private var newValue = ""
    @State private var newActionType: SnippetActionType = .text

    var body: some View {
        VStack(spacing: 0) {
            // Add new snippet
            HStack {
                TextField("Trigger phrase", text: $newTrigger)
                    .textFieldStyle(.roundedBorder)
                Picker("Type", selection: $newActionType) {
                    Text("Text").tag(SnippetActionType.text)
                    Text("Shell").tag(SnippetActionType.shell)
                    Text("Key").tag(SnippetActionType.keystroke)
                }
                .frame(width: 100)
                TextField("Value", text: $newValue)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addSnippet()
                }
                .disabled(newTrigger.isEmpty || newValue.isEmpty)
            }
            .padding()

            Divider()

            List {
                ForEach(snippets) { snippet in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(snippet.trigger)
                                .font(.body.weight(.medium))
                            Text(snippet.value)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(snippet.actionType.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.15))
                            .clipShape(Capsule())
                        Text("\(snippet.usageCount)x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteSnippets)
            }
        }
    }

    private func addSnippet() {
        let snippet = Snippet(trigger: newTrigger, actionType: newActionType, value: newValue)
        modelContext.insert(snippet)
        newTrigger = ""
        newValue = ""
    }

    private func deleteSnippets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(snippets[index])
        }
    }
}
