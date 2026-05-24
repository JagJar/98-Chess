import Foundation
import SwiftData

enum GameOutcome: String {
    case win, loss, draw, resign
}

@Model
final class GameResult {
    @Attribute(.unique) var id: UUID = UUID()
    var finishedAt: Date = Date.now
    /// startOfDay normalized to user's calendar; lets us group results by day.
    var dayKey: Date = Date.now
    /// Raw value of `GameOutcome`.
    var outcomeRaw: String = GameOutcome.draw.rawValue
    /// Raw value of `Difficulty`.
    var difficultyRaw: String = ""
    /// Total plies played (not full moves).
    var moveCount: Int = 0
    var xpAwarded: Int = 0

    init(
        finishedAt: Date = .now,
        dayKey: Date,
        outcome: GameOutcome,
        difficultyRaw: String,
        moveCount: Int,
        xpAwarded: Int
    ) {
        self.finishedAt = finishedAt
        self.dayKey = dayKey
        self.outcomeRaw = outcome.rawValue
        self.difficultyRaw = difficultyRaw
        self.moveCount = moveCount
        self.xpAwarded = xpAwarded
    }

    var outcome: GameOutcome {
        GameOutcome(rawValue: outcomeRaw) ?? .draw
    }
}
