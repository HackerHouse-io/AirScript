import Foundation

struct ProcessingContext {
    var styleInstruction: String?
    var appBundleID: String?
    var visibleText: String?
    var isBacktrackingEnabled: Bool = false
    var previousTranscript: String?
}
