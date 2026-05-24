import Foundation
import SwiftData

@Model
final class UnlockedAchievement {
    @Attribute(.unique) var achievementID: String = ""
    var unlockedAt: Date = Date.now
    /// True until the user views the unlocked achievement in the Achievements
    /// window. Drives the "(!)" menu badge.
    var isNew: Bool = true

    init(achievementID: String, unlockedAt: Date = .now, isNew: Bool = true) {
        self.achievementID = achievementID
        self.unlockedAt = unlockedAt
        self.isNew = isNew
    }
}
