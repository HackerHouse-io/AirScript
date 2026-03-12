import SwiftUI

struct ModelRowView: View {
    let model: ModelInfo
    var onDownload: (() async -> Void)? = nil
    let onDelete: () -> Void
    var isActive: Bool = false
    var onSelect: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil

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
                HStack(spacing: 4) {
                    Text(model.sizeDescription)
                        .font(AirScriptTheme.fontCaption)
                        .foregroundStyle(AirScriptTheme.textSecondary)
                    if let params = model.parameterCount {
                        Text("·")
                            .font(AirScriptTheme.fontCaption)
                            .foregroundStyle(AirScriptTheme.textSecondary)
                        Text(params)
                            .font(AirScriptTheme.fontCaption)
                            .foregroundStyle(AirScriptTheme.textSecondary)
                    }
                }
            }

            Spacer()

            if model.isDownloading {
                HStack(spacing: 8) {
                    ProgressView(value: max(0, model.downloadProgress))
                        .frame(width: 80)
                    Text("\(Int(max(0, model.downloadProgress) * 100))%")
                        .font(AirScriptTheme.fontCaption)
                        .foregroundStyle(AirScriptTheme.textSecondary)
                        .monospacedDigit()
                    if let onCancel {
                        Button("Cancel", role: .destructive) {
                            onCancel()
                        }
                        .buttonStyle(.borderless)
                        .font(AirScriptTheme.fontCaption)
                    }
                }
            } else if isActive {
                HStack(spacing: 8) {
                    StatusBadge(text: "Loaded", color: AirScriptTheme.statusSuccess)
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    .buttonStyle(.borderless)
                    .font(AirScriptTheme.fontCaption)
                }
            } else if model.isDownloaded {
                HStack(spacing: 8) {
                    if let onSelect {
                        Button("Load") {
                            onSelect()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    .buttonStyle(.borderless)
                    .font(AirScriptTheme.fontCaption)
                }
            } else if !model.isDownloadable {
                Text("Coming Soon")
                    .font(AirScriptTheme.fontCaption)
                    .foregroundStyle(AirScriptTheme.textTertiary)
            } else if let onDownload {
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
