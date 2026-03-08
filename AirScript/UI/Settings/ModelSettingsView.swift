import SwiftUI

struct ModelSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ModelManagerView()
                .environment(appState)
        }
        .padding()
    }
}
