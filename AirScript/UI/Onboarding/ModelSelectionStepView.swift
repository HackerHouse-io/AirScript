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
                                onDelete: { deleteModel(model.name) },
                                isActive: model.id == appState.selectedWhisperModel && appState.isWhisperModelLoaded,
                                onSelect: { appState.selectedWhisperModel = model.name },
                                onCancel: { modelManager.cancelDownload() }
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
        appState.isWhisperModelDownloading = true
        appState.modelDownloadProgress = 0
        defer {
            appState.isWhisperModelDownloading = false
            appState.modelDownloadProgress = 0
        }
        do {
            try await modelManager.startDownload(named: name) { progress in
                appState.modelDownloadProgress = progress
            }
            appState.selectedWhisperModel = name
        } catch is CancellationError {
            // User cancelled
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func deleteModel(_ name: String) {
        if name == appState.selectedWhisperModel {
            appState.transcriptionEngine.unloadModel()
            appState.isWhisperModelLoaded = false

            let fallback = modelManager.availableModels
                .first(where: { $0.id != name && $0.isDownloaded })?.id
                ?? Constants.Defaults.whisperModel
            appState.selectedWhisperModel = fallback
        }
        do {
            try modelManager.deleteModel(named: name)
        } catch {
            appState.lastError = error.localizedDescription
        }
    }
}
