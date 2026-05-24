import Foundation

/// Pure date math for streak transitions. Stateless, testable, no SwiftData
/// references. Caller passes in the relevant fields and applies the result.
enum StreakCalculator {

    /// What should happen to the streak when the app launches, given how long
    /// since the user last played.
    enum LaunchOutcome: Equatable {
        /// No prior play, or last play was today or yesterday — no change to
        /// the streak from app launch alone.
        case noChange
        /// Last play was 2 days ago and a freeze is available. Freeze is
        /// consumed, the missed day counts as covered, streak survives.
        case freezeApplied(missedDay: Date)
        /// Last play was 2+ days ago and no freeze can save it. Streak breaks
        /// and should reset to 0.
        case broken
    }

    /// What should happen to the streak when the user finishes a game.
    enum CompletionOutcome: Equatable {
        /// Already played today — streak unchanged.
        case sameDay
        /// Played yesterday (or freeze covered yesterday) — increment streak.
        case continuing
        /// Either no prior play or a gap longer than the freeze can cover —
        /// streak restarts at 1.
        case newStreak
    }

    static func evaluateLaunch(
        lastPlayedDay: Date?,
        freezesAvailable: Int,
        today: Date,
        calendar: Calendar = .current
    ) -> LaunchOutcome {
        guard let last = lastPlayedDay else { return .noChange }
        let lastDay = calendar.startOfDay(for: last)
        let todayDay = calendar.startOfDay(for: today)
        let days = calendar.dateComponents([.day], from: lastDay, to: todayDay).day ?? 0
        switch days {
        case ...1:
            return .noChange
        case 2 where freezesAvailable > 0:
            let missed = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay
            return .freezeApplied(missedDay: missed)
        default:
            return .broken
        }
    }

    static func evaluateCompletion(
        lastPlayedDay: Date?,
        today: Date,
        calendar: Calendar = .current
    ) -> CompletionOutcome {
        guard let last = lastPlayedDay else { return .newStreak }
        let lastDay = calendar.startOfDay(for: last)
        let todayDay = calendar.startOfDay(for: today)
        let days = calendar.dateComponents([.day], from: lastDay, to: todayDay).day ?? 0
        switch days {
        case 0:  return .sameDay
        case 1:  return .continuing
        default: return .newStreak
        }
    }

    /// Returns the start of the current ISO week (Monday) in the given calendar.
    static func startOfWeek(containing date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}
