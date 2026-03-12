import SwiftUI

struct ModelManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var modelManager = ModelManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Whisper Models")
                .font(.headline)

            if modelManager.isLoading {
                ProgressView("Loading models...")
            } else {
                RecommendationBanner(
                    modelName: modelManager.availableModels.first(where: {
                        $0.id == modelManager.recommendedWhisperModel()
                    })?.displayName ?? modelManager.recommendedWhisperModel()
                )

                ForEach(modelManager.availableModels) { model in
                    ModelRowView(
                        model: model,
                        onDownload: { await downloadModel(model.name) },
                        onDelete: { deleteModel(model.name) },
                        isActive: model.id == appState.selectedWhisperModel && appState.isWhisperModelLoaded,
                        onSelect: { appState.switchWhisperModel(to: model.name) },
                        onCancel: { modelManager.cancelDownload() }
                    )
                }

                if let error = appState.lastError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(AirScriptTheme.fontCaption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400)
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
        } catch is CancellationError {
            // User cancelled — no error needed
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func deleteModel(_ name: String) {
        if name == appState.selectedWhisperModel {
            appState.transcriptionEngine.unloadModel()
            appState.isWhisperModelLoaded = false

            // Fall back to the first remaining downloaded model, or the computed default
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
