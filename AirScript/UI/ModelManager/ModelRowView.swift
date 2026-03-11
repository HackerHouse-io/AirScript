import SwiftUI

struct ModelRowView: View {
    let model: ModelInfo
    let onDownload: () async -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .font(AirScriptTheme.fontBodyMedium)
                    if model.isRecommended {
                        StatusBadge(text: "Recommended", style: .mono)
                    }
                }
                Text(model.sizeDescription)
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.textSecondary)
            }

            Spacer()

            if model.isDownloading {
                ProgressView()
                    .scaleEffect(0.7)
            } else if model.isDownloaded {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AirScriptTheme.statusSuccess)
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    .buttonStyle(.borderless)
                    .font(AirScriptTheme.fontCaption)
                }
            } else {
                Button("Download") {
                    Task { await onDownload() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
