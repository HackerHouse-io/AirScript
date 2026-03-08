import os

extension Logger {
    static let audio = Logger(subsystem: Constants.subsystem, category: "audio")
    static let transcription = Logger(subsystem: Constants.subsystem, category: "transcription")
    static let llm = Logger(subsystem: Constants.subsystem, category: "llm")
    static let hotkey = Logger(subsystem: Constants.subsystem, category: "hotkey")
    static let injection = Logger(subsystem: Constants.subsystem, category: "injection")
    static let commands = Logger(subsystem: Constants.subsystem, category: "commands")
    static let context = Logger(subsystem: Constants.subsystem, category: "context")
    static let formatting = Logger(subsystem: Constants.subsystem, category: "formatting")
    static let models = Logger(subsystem: Constants.subsystem, category: "models")
    static let ui = Logger(subsystem: Constants.subsystem, category: "ui")
    static let general = Logger(subsystem: Constants.subsystem, category: "general")
}
