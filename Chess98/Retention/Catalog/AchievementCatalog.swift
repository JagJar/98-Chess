import Foundation

/// All achievement definitions known to the app. IDs are stable forever;
/// new entries append, never renumber.
enum AchievementCatalog {
    static let all: [Achievement] = [
        // Getting started
        Achievement(
            id: "first_game", title: "Hello, World",
            description: "Play your first game",
            tier: .bronze,
            predicate: { $0.stats.gamesPlayed >= 1 }
        ),
        Achievement(
            id: "first_win", title: "Victory",
            description: "Win your first game",
            tier: .bronze,
            predicate: { $0.stats.wins >= 1 }
        ),
        Achievement(
            id: "first_draw", title: "Almost",
            description: "Draw a game",
            tier: .bronze,
            predicate: { $0.stats.draws >= 1 }
        ),

        // Win volume
        Achievement(
            id: "win_10", title: "Decimal",
            description: "Win 10 games",
            tier: .bronze,
            predicate: { $0.stats.wins >= 10 }
        ),
        Achievement(
            id: "win_50", title: "Hex",
            description: "Win 50 games",
            tier: .silver,
            predicate: { $0.stats.wins >= 50 }
        ),
        Achievement(
            id: "win_100", title: "Centurion",
            description: "Win 100 games",
            tier: .gold,
            predicate: { $0.stats.wins >= 100 }
        ),

        // Difficulty ladder
        Achievement(
            id: "beat_beginner", title: "Tutorial Complete",
            description: "Beat the Beginner opponent",
            tier: .bronze,
            predicate: { $0.stats.hasWonAt(difficultyRaw: Difficulty.beginner.rawValue) }
        ),
        Achievement(
            id: "beat_easy", title: "Warmed Up",
            description: "Beat the Easy opponent",
            tier: .bronze,
            predicate: { $0.stats.hasWonAt(difficultyRaw: Difficulty.easy.rawValue) }
        ),
        Achievement(
            id: "beat_medium", title: "Solid Player",
            description: "Beat the Medium opponent",
            tier: .silver,
            predicate: { $0.stats.hasWonAt(difficultyRaw: Difficulty.medium.rawValue) }
        ),
        Achievement(
            id: "beat_hard", title: "Tournament Ready",
            description: "Beat the Hard opponent",
            tier: .silver,
            predicate: { $0.stats.hasWonAt(difficultyRaw: Difficulty.hard.rawValue) }
        ),
        Achievement(
            id: "beat_master", title: "Grandmaster",
            description: "Beat the Master opponent",
            tier: .gold,
            predicate: { $0.stats.hasWonAt(difficultyRaw: Difficulty.master.rawValue) }
        ),

        // Streaks
        Achievement(
            id: "streak_3", title: "Habit Forming",
            description: "Reach a 3-day streak",
            tier: .bronze,
            predicate: { $0.stats.currentStreak >= 3 }
        ),
        Achievement(
            id: "streak_7", title: "One Week",
            description: "Reach a 7-day streak",
            tier: .silver,
            predicate: { $0.stats.currentStreak >= 7 }
        ),
        Achievement(
            id: "streak_30", title: "Devoted",
            description: "Reach a 30-day streak",
            tier: .gold,
            predicate: { $0.stats.currentStreak >= 30 }
        ),

        // Puzzles (predicates evaluate against stats updated in commit 4)
        Achievement(
            id: "puzzle_first", title: "Puzzle Solver",
            description: "Solve your first daily puzzle",
            tier: .bronze,
            predicate: { $0.stats.puzzlesSolvedTotal >= 1 }
        ),
        Achievement(
            id: "puzzle_10", title: "Tactician",
            description: "Solve 10 daily puzzles",
            tier: .silver,
            predicate: { $0.stats.puzzlesSolvedTotal >= 10 }
        ),

        // Style
        Achievement(
            id: "quick_mate", title: "Lightning Strike",
            description: "Win in 10 moves or fewer",
            tier: .silver,
            predicate: { ctx in
                guard let r = ctx.lastResult, r.outcome == .win else { return false }
                return r.moveCount <= 20  // plies — 10 full moves
            }
        )
    ]

    static func find(id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}
