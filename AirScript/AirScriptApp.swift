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
        // Main app window
        WindowGroup {
            MainAppView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        }
        .defaultSize(width: 900, height: 620)
        .windowResizability(.contentMinSize)

        // Menu bar icon
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        } label: {
            Image(systemName: menuBarIcon)
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        // Settings (Cmd+,)
        Settings {
            SettingsView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        }

        // Onboarding
        Window("AirScript Setup", id: "onboarding") {
            OnboardingView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }

    private var menuBarIcon: String {
        if appState.isRecording { return "mic.fill" }
        if appState.isProcessing { return "brain" }
        return "mic"
    }

    init() {
        // Ensure app support directories exist
        try? URL.ensureDirectoryExists(URL.airScriptSupport)
        try? URL.ensureDirectoryExists(URL.whisperModels)
        try? URL.ensureDirectoryExists(URL.llmModels)
        try? URL.ensureDirectoryExists(URL.audioRecordings)
    }
}
