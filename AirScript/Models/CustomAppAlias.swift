import Foundation
import SwiftData

@Model
final class CustomAppAlias {
    @Attribute(.unique) var id: UUID
    var spokenName: String
    var appName: String
    var createdAt: Date

    init(spokenName: String, appName: String) {
        self.id = UUID()
        self.spokenName = spokenName
        self.appName = appName
        self.createdAt = Date()
    }
}
