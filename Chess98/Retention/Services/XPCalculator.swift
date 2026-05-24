import Foundation

enum XPCalculator {
    /// XP awarded for playing any game (regardless of outcome).
    static let basePerGame = 5

    /// XP awarded for solving the daily puzzle (excluding hint bonus).
    static let perPuzzleSolve = 25

    /// Bonus XP for solving the daily puzzle without using the hint.
    static let noHintBonus = 10

    /// Win XP bonus, by difficulty raw value.
    static func winBonus(forDifficulty diff: Difficulty) -> Int {
        switch diff {
        case .beginner: 10
        case .easy:     20
        case .medium:   40
        case .hard:     80
        case .master:   150
        }
    }

    /// XP awarded for a draw at any difficulty.
    static let drawBonus = 15

    /// Total XP for a game outcome at a given difficulty.
    /// Resignation = base only (no bonus). Win = base + win bonus.
    /// Draw = base + draw bonus. Loss = base only.
    static func xp(for outcome: GameOutcome, difficulty: Difficulty) -> Int {
        switch outcome {
        case .win:    basePerGame + winBonus(forDifficulty: difficulty)
        case .draw:   basePerGame + drawBonus
        case .loss:   basePerGame
        case .resign: basePerGame
        }
    }

    /// Streak milestone bonus XP. Returns 0 for any value that isn't a defined milestone.
    static func streakMilestoneBonus(forNewStreak streak: Int) -> Int {
        switch streak {
        case 7:   50
        case 30:  200
        case 100: 500
        default:  0
        }
    }
}
