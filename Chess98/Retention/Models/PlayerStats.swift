import Foundation
import SwiftData

/// Singleton record. `RetentionService` ensures only one row exists.
@Model
final class PlayerStats {
    // MARK: Game totals
    var gamesPlayed: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var draws: Int = 0
    var resignations: Int = 0

    /// JSON-encoded `[String: Int]` keyed by `Difficulty.rawValue`.
    /// Encoded as string for cross-version SwiftData stability.
    var winsByDifficultyRaw: String = "{}"

    // MARK: Streak
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastPlayedDay: Date?
    var streakFreezesAvailable: Int = 0
    var lastFreezeRefillWeek: Date?
    var freezeUsedOn: Date?

    // MARK: XP
    var xpTotal: Int = 0

    // MARK: Puzzles
    var puzzlesSolvedTotal: Int = 0
    var puzzlesAttempted: Int = 0
    var lastPuzzleDay: Date?
    var puzzlesSolvedToday: Bool = false

    // MARK: Preferences / onboarding
    var firstLaunchAt: Date = Date.now
    var notificationsEnabled: Bool = false
    var notificationHour: Int = 19
    var notificationMinute: Int = 0
    var onboardingCompleted: Bool = false

    init() {}

    // MARK: Derived

    /// Player level from total XP. `level = floor(sqrt(xpTotal / 50)) + 1`.
    var level: Int {
        Int(Double(xpTotal / 50).squareRoot().rounded(.down)) + 1
    }

    /// Total XP required to reach a given level. `xp(n) = 50 * (n-1)^2`.
    static func xpForLevel(_ level: Int) -> Int {
        50 * (level - 1) * (level - 1)
    }

    /// Win rate as a fraction in [0, 1]. Returns 0 when no games played.
    var winRate: Double {
        gamesPlayed > 0 ? Double(wins) / Double(gamesPlayed) : 0
    }

    // MARK: winsByDifficulty helpers

    func winsByDifficulty() -> [String: Int] {
        guard let data = winsByDifficultyRaw.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        return dict
    }

    func recordWin(difficultyRaw: String) {
        var dict = winsByDifficulty()
        dict[difficultyRaw, default: 0] += 1
        if let data = try? JSONEncoder().encode(dict),
           let str = String(data: data, encoding: .utf8) {
            winsByDifficultyRaw = str
        }
    }

    func hasWonAt(difficultyRaw: String) -> Bool {
        (winsByDifficulty()[difficultyRaw] ?? 0) >= 1
    }
}
