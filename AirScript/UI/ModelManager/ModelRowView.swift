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
                        .font(.subheadline.weight(.medium))
                    if model.isRecommended {
                        Text("Recommended")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                Text(model.sizeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if model.isDownloading {
                ProgressView()
                    .scaleEffect(0.7)
            } else if model.isDownloaded {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
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
