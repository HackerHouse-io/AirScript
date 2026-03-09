import SwiftUI

struct ModelSelectionStepView: View {
    @Environment(AppState.self) private var appState
    @State private var modelManager = ModelManager()

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose a Model")
                .font(.title2)
            Text("Select a Whisper model for speech recognition. Larger models are more accurate but use more RAM.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if modelManager.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(modelManager.availableModels) { model in
                            ModelRowView(
                                model: model,
                                onDownload: { await downloadModel(model.name) },
                                onDelete: { deleteModel(model.name) }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding()
        .task {
            await modelManager.fetchAvailableModels()
        }
    }

    private func downloadModel(_ name: String) async {
        do {
            try await modelManager.downloadModel(named: name)
            appState.selectedWhisperModel = name
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func deleteModel(_ name: String) {
        do {
            try modelManager.deleteModel(named: name)
        } catch {
            appState.lastError = error.localizedDescription
        }
    }
}
