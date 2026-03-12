import SwiftUI

struct ModelSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ModelManagerView()
                    .environment(appState)

                Divider()

                LLMModelManagerView()
                    .environment(appState)
            }
            .padding()
        }
    }
}
