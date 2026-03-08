import Foundation

enum Constants {
    static let subsystem = "io.hackerhouse.AirScript"

    enum Defaults {
        static let whisperModel = "openai_whisper-large-v3-v20240930"
        static let llmModel = "mlx-community/Llama-3.2-3B-Instruct-4bit"
        static let sampleRate: Double = 16000
        static let audioChannels: Int = 1
        static let maxHandsFreeDuration: TimeInterval = 360 // 6 minutes
        static let handsFreeWarningDuration: TimeInterval = 300 // 5 minutes
        static let doubleTapInterval: TimeInterval = 0.3
        static let clipboardRestoreDelay: TimeInterval = 0.5
        static let vadOnsetThreshold: Float = 0.01
        static let vadOffsetThreshold: Float = 0.005
        static let vadOnsetDuration: TimeInterval = 0.1
        static let vadOffsetDuration: TimeInterval = 0.7
        static let ringBufferDuration: TimeInterval = 30
        static let incrementalInferenceInterval: TimeInterval = 3
    }

    enum Paths {
        static let appSupport = "AirScript"
        static let whisperModels = "Models/whisper"
        static let llmModels = "Models/llm"
        static let audioRecordings = "Audio"
    }

    enum BundleIDs {
        static let slack = "com.tinyspeck.slackmacgap"
        static let messages = "com.apple.MobileSMS"
        static let mail = "com.apple.mail"
        static let notes = "com.apple.Notes"
        static let vscode = "com.microsoft.VSCode"
        static let cursor = "todesktop.com.Cursor"
        static let xcode = "com.apple.dt.Xcode"
        static let windsurf = "com.codeium.windsurf"
        static let safari = "com.apple.Safari"
        static let chrome = "com.google.Chrome"
        static let discord = "com.hnc.Discord"
        static let telegram = "ru.keepcoder.Telegram"
        static let whatsapp = "net.whatsapp.WhatsApp"
    }
}
