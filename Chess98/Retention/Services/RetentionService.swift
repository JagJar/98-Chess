import Foundation
import Observation
import SwiftData

/// Central orchestrator for all retention writes. ContentView holds a single
/// instance and routes game-completion and puzzle events through it. This is
/// the ONLY type that writes to `PlayerStats`, `UnlockedAchievement`,
/// `GameResult`, or `DailyPuzzleAttempt`.
@Observable
final class RetentionService {
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let calendar: Calendar

    /// The single PlayerStats record. Created on first launch if absent.
    private(set) var stats: PlayerStats

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
        self.stats = Self.fetchOrCreateStats(in: context)
    }

    /// Called once during app launch — keeps daily flags fresh.
    func onAppLaunch() {
        let today = calendar.startOfDay(for: .now)
        if let lastPuzzle = stats.lastPuzzleDay,
           calendar.startOfDay(for: lastPuzzle) != today {
            stats.puzzlesSolvedToday = false
        }
        save()
    }

    /// Called when a game transitions from in-progress to game-over (any cause:
    /// checkmate, draw, resignation). Returns the XP awarded so the caller can
    /// surface it if desired.
    @discardableResult
    func onGameFinished(
        outcome: GameOutcome,
        difficulty: Difficulty,
        moveCount: Int
    ) -> Int {
        let today = calendar.startOfDay(for: .now)
        let xp = XPCalculator.xp(for: outcome, difficulty: difficulty)

        stats.gamesPlayed += 1
        switch outcome {
        case .win:
            stats.wins += 1
            stats.recordWin(difficultyRaw: difficulty.rawValue)
        case .loss:
            stats.losses += 1
        case .draw:
            stats.draws += 1
        case .resign:
            stats.losses += 1
            stats.resignations += 1
        }
        stats.xpTotal += xp
        stats.lastPlayedDay = today

        let result = GameResult(
            dayKey: today,
            outcome: outcome,
            difficultyRaw: difficulty.rawValue,
            moveCount: moveCount,
            xpAwarded: xp
        )
        context.insert(result)

        pruneOldResults()
        save()
        return xp
    }

    // MARK: - Internals

    private static func fetchOrCreateStats(in context: ModelContext) -> PlayerStats {
        let descriptor = FetchDescriptor<PlayerStats>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let new = PlayerStats()
        context.insert(new)
        try? context.save()
        return new
    }

    /// Keep at most the most recent 200 GameResult rows to bound storage.
    private func pruneOldResults() {
        let descriptor = FetchDescriptor<GameResult>(
            sortBy: [SortDescriptor(\.finishedAt, order: .reverse)]
        )
        guard let results = try? context.fetch(descriptor), results.count > 200 else { return }
        for stale in results.dropFirst(200) {
            context.delete(stale)
        }
    }

    private func save() {
        try? context.save()
    }
}
