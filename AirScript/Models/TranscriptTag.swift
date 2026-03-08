import Foundation
import SwiftData

@Model
final class TranscriptTag {
    @Attribute(.unique) var name: String
    var transcripts: [Transcript]

    init(name: String) {
        self.name = name
        self.transcripts = []
    }
}
