import Foundation

extension URL {
    static var airScriptSupport: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Constants.Paths.appSupport)
    }

    static var whisperModels: URL {
        airScriptSupport.appendingPathComponent(Constants.Paths.whisperModels)
    }

    static var llmModels: URL {
        airScriptSupport.appendingPathComponent(Constants.Paths.llmModels)
    }

    static var audioRecordings: URL {
        airScriptSupport.appendingPathComponent(Constants.Paths.audioRecordings)
    }

    static func ensureDirectoryExists(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
