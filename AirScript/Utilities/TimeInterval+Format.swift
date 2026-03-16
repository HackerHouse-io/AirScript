import Foundation

extension TimeInterval {
    var compactDuration: String {
        let seconds = Int(self)
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }
}
