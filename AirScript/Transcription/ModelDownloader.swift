import Foundation
import os

struct DownloadProgress {
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let progress: Double
    let estimatedTimeRemaining: TimeInterval?
}

actor ModelDownloader {
    private let logger = Logger.models

    func download(
        from url: URL,
        to destination: URL,
        progressHandler: @escaping (DownloadProgress) -> Void
    ) async throws {
        try URL.ensureDirectoryExists(destination.deletingLastPathComponent())

        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DownloadError.httpError
        }

        let totalBytes = response.expectedContentLength
        var downloadedBytes: Int64 = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        var data = Data()
        data.reserveCapacity(totalBytes > 0 ? Int(totalBytes) : 1024 * 1024)

        for try await byte in asyncBytes {
            data.append(byte)
            downloadedBytes += 1

            if downloadedBytes % (1024 * 100) == 0 { // report every 100KB
                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                let rate = Double(downloadedBytes) / elapsed
                let remaining = totalBytes > 0
                    ? TimeInterval(Double(totalBytes - downloadedBytes) / rate)
                    : nil

                progressHandler(DownloadProgress(
                    bytesDownloaded: downloadedBytes,
                    totalBytes: totalBytes,
                    progress: totalBytes > 0 ? Double(downloadedBytes) / Double(totalBytes) : 0,
                    estimatedTimeRemaining: remaining
                ))
            }
        }

        try data.write(to: destination, options: .atomic)
        logger.info("Download complete: \(destination.lastPathComponent)")
    }
}

enum DownloadError: Error, LocalizedError {
    case httpError
    case checksumMismatch

    var errorDescription: String? {
        switch self {
        case .httpError: "HTTP request failed"
        case .checksumMismatch: "File checksum verification failed"
        }
    }
}
