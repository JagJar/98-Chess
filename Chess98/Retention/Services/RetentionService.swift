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

    /// Called once during app launch — refills weekly freeze, evaluates
    /// streak rollover, resets daily puzzle flag.
    func onAppLaunch() {
        let now = Date.now
        let today = calendar.startOfDay(for: now)

        // Weekly freeze refill (cap 1).
        let weekStart = StreakCalculator.startOfWeek(containing: now, calendar: calendar)
        if stats.lastFreezeRefillWeek != weekStart {
            stats.streakFreezesAvailable = 1
            stats.lastFreezeRefillWeek = weekStart
        }

        // Streak rollover based on time since last play.
        let outcome = StreakCalculator.evaluateLaunch(
            lastPlayedDay: stats.lastPlayedDay,
            freezesAvailable: stats.streakFreezesAvailable,
            today: now,
            calendar: calendar
        )
        switch outcome {
        case .noChange:
            break
        case .freezeApplied(let missedDay):
            stats.streakFreezesAvailable -= 1
            stats.freezeUsedOn = missedDay
            // Treat the freeze day as if it had been played, so the next play
            // increments rather than resets.
            stats.lastPlayedDay = missedDay
        case .broken:
            stats.currentStreak = 0
        }

        // Daily puzzle flag reset.
        if let lastPuzzle = stats.lastPuzzleDay,
           calendar.startOfDay(for: lastPuzzle) != today {
            stats.puzzlesSolvedToday = false
        }
        save()
    }

    /// Clears the one-time "freeze used" flag once the UI has shown the toast.
    func clearFreezeNotice() {
        stats.freezeUsedOn = nil
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
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        var xp = XPCalculator.xp(for: outcome, difficulty: difficulty)

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

        // Streak handling.
        let completion = StreakCalculator.evaluateCompletion(
            lastPlayedDay: stats.lastPlayedDay,
            today: now,
            calendar: calendar
        )
        switch completion {
        case .sameDay:
            break
        case .continuing:
            stats.currentStreak += 1
            xp += XPCalculator.streakMilestoneBonus(forNewStreak: stats.currentStreak)
        case .newStreak:
            stats.currentStreak = 1
            xp += XPCalculator.streakMilestoneBonus(forNewStreak: 1)
        }
        if stats.currentStreak > stats.longestStreak {
            stats.longestStreak = stats.currentStreak
        }
        stats.lastPlayedDay = today
        stats.xpTotal += xp

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
