import SwiftUI

struct DownloadProgressView: View {
    let progress: Double
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let estimatedTimeRemaining: TimeInterval?
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: progress)

            HStack {
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let eta = estimatedTimeRemaining {
                    Text(formatETA(eta))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
    }

    private var progressText: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
        if totalBytes > 0 {
            let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            return "\(downloaded) / \(total) (\(Int(progress * 100))%)"
        }
        return downloaded
    }

    private func formatETA(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s remaining"
        } else {
            return "\(Int(seconds / 60))m \(Int(seconds.truncatingRemainder(dividingBy: 60)))s remaining"
        }
    }
}
