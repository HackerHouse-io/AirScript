import SwiftUI

struct StatusItemView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Image(systemName: statusIcon)
            .symbolRenderingMode(.hierarchical)
    }

    private var statusIcon: String {
        if appState.isRecording {
            return "mic.fill"
        } else if appState.isProcessing {
            return "brain"
        } else {
            return "mic"
        }
    }
}
