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
                recommendationBanner

                ForEach(modelManager.availableModels) { model in
                    ModelRowView(
                        model: model,
                        onDownload: { await downloadModel(model.name) },
                        onDelete: { deleteModel(model.name) }
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

    @ViewBuilder
    private var recommendationBanner: some View {
        let recommended = modelManager.recommendedWhisperModel()
        let ramGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)

        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            Text("Recommended for your Mac (\(Int(ramGB))GB RAM): **\(recommended)**")
                .font(.subheadline)
        }
        .padding(8)
        .background(.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func downloadModel(_ name: String) async {
        do {
            try await modelManager.downloadModel(named: name)
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
