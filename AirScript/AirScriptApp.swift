import SwiftUI
import SwiftData

@main
struct AirScriptApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transcript.self,
            TranscriptTag.self,
            DictionaryEntry.self,
            Snippet.self,
            AppStyle.self,
            AirNote.self,
            WhisperModelRecord.self,
            LLMModelRecord.self,
            CorrectionLog.self,
            ProductivityStat.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        } label: {
            Image(systemName: appState.isRecording ? "mic.fill" : "mic")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
