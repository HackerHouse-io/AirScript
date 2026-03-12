import SwiftUI

struct LLMModelManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var modelManager = LLMModelManager()
    @State private var downloadError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LLM Models")
                .font(.headline)

            if modelManager.isLoading {
                ProgressView("Loading models...")
            } else {
                RecommendationBanner(
                    modelName: modelManager.availableModels.first(where: {
                        $0.id == modelManager.recommendedLLMModel()
                    })?.displayName ?? modelManager.recommendedLLMModel()
                )

                ForEach(modelManager.availableModels) { model in
                    ModelRowView(
                        model: model,
                        onDownload: { await downloadModel(model.name) },
                        onDelete: { deleteModel(model.name) },
                        isActive: model.id == appState.selectedLLMModel && appState.isLLMModelLoaded,
                        onSelect: { appState.switchLLMModel(to: model.name) },
                        onCancel: { modelManager.cancelDownload() }
                    )
                }

                if let error = downloadError {
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
        downloadError = nil
        appState.isLLMModelDownloading = true
        appState.llmModelDownloadProgress = 0
        defer {
            appState.isLLMModelDownloading = false
            appState.llmModelDownloadProgress = 0
        }
        do {
            try await modelManager.startDownload(named: name) { [appState] progress in
                Task { @MainActor in
                    appState.llmModelDownloadProgress = progress
                }
            }
        } catch is CancellationError {
            // User cancelled
        } catch {
            downloadError = error.localizedDescription
        }
    }

    private func deleteModel(_ name: String) {
        if name == appState.selectedLLMModel {
            appState.llmProcessor.unloadModel()
            appState.isLLMModelLoaded = false

            let fallback = modelManager.availableModels
                .first(where: { $0.id != name && $0.isDownloaded })?.id
                ?? Constants.Defaults.llmModel
            appState.selectedLLMModel = fallback
        }
        do {
            try modelManager.deleteModel(named: name)
        } catch {
            downloadError = error.localizedDescription
        }
    }
}
