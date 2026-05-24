import Foundation
import SwiftData

@Model
final class DailyPuzzleAttempt {
    @Attribute(.unique) var puzzleID: String = ""
    var firstAttemptAt: Date = Date.now
    var solvedAt: Date?
    var attempts: Int = 0
    var solvedFromHint: Bool = false

    init(
        puzzleID: String,
        firstAttemptAt: Date = .now,
        solvedAt: Date? = nil,
        attempts: Int = 0,
        solvedFromHint: Bool = false
    ) {
        self.puzzleID = puzzleID
        self.firstAttemptAt = firstAttemptAt
        self.solvedAt = solvedAt
        self.attempts = attempts
        self.solvedFromHint = solvedFromHint
    }

    var isSolved: Bool { solvedAt != nil }
}
