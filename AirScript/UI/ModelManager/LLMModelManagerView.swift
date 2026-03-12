import SwiftUI

struct LLMModelManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var modelManager = LLMModelManager()

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
                        onDelete: { deleteModel(model.name) },
                        isActive: model.id == appState.selectedLLMModel && appState.isLLMModelLoaded,
                        onSelect: { appState.switchLLMModel(to: model.name) }
                    )
                }
            }
        }
        .padding()
        .frame(minWidth: 400)
        .task {
            await modelManager.fetchAvailableModels()
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
            appState.lastError = error.localizedDescription
        }
    }
}
