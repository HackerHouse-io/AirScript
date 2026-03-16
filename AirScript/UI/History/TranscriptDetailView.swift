import SwiftUI
import SwiftData

struct TranscriptDetailView: View {
    let transcript: Transcript
    @Environment(\.modelContext) private var modelContext
    @State private var showRawText = false
    @State private var showDeleteConfirmation = false
    var onDelete: (() -> Void)?

    var body: some View {
        AirSheet(title: "Transcript Detail") {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(transcript.createdAt, style: .date)
                                .font(AirScriptTheme.fontSectionTitle)
                            Text(transcript.createdAt, style: .time)
                                .font(AirScriptTheme.fontSubtitle)
                                .foregroundStyle(AirScriptTheme.textSecondary)
                        }
                        Spacer()
                        if let appName = transcript.appName {
                            StatusBadge(text: appName, style: .mono)
                        }
                    }

                    // Metadata
                    HStack(spacing: 16) {
                        metadataItem("Duration", value: transcript.duration.compactDuration)
                        metadataItem("Words", value: "\(transcript.wordCount)")
                        metadataItem("WPM", value: String(format: "%.0f", transcript.wordsPerMinute))
                        metadataItem("Model", value: transcript.model)
                    }

                    Divider()

                    Toggle("Show raw ASR text", isOn: $showRawText)
                        .toggleStyle(.switch)
                        .controlSize(.small)

                    // Text content
                    Text(showRawText ? transcript.rawText : transcript.text)
                        .font(AirScriptTheme.fontBodyPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AirScriptTheme.Radius.md))

                    // Actions
                    HStack {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(transcript.text, forType: .string)
                        }
                        .buttonStyle(.bordered)

                        Button("Re-inject") {
                            Task {
                                await TextInjector.inject(text: transcript.text)
                            }
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("Delete", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .alert("Delete Transcript", isPresented: $showDeleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(transcript)
                            onDelete?()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This transcript will be permanently deleted.")
                    }
                }
                .padding()
            }
        }
    }

    private func metadataItem(_ label: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(AirScriptTheme.fontBodyMedium)
            Text(label)
                .font(AirScriptTheme.fontCaption2)
                .foregroundStyle(AirScriptTheme.textSecondary)
        }
    }
}
