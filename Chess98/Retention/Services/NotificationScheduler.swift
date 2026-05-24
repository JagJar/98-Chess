import Foundation
import UserNotifications

/// Thin wrapper over UNUserNotificationCenter. No remote/push notifications,
/// no analytics — purely local daily reminders.
final class NotificationScheduler {
    static let dailyReminderIdentifierPrefix = "daily-reminder-"
    private let center = UNUserNotificationCenter.current()

    /// Requests the user's authorization to send notifications. Returns
    /// whether the user granted permission.
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Returns the current authorization status (not denied / authorized /
    /// provisional / etc).
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Cancels every pending daily-reminder request and schedules a fresh
    /// 14-day batch firing at `hour:minute` each day. Body text is computed
    /// per day via `bodyProvider(dayOffset)` so we can vary the wording.
    func rescheduleDailyReminders(
        hour: Int,
        minute: Int,
        bodyProvider: (Int) -> String,
        now: Date = .now,
        calendar: Calendar = .current
    ) async {
        await cancelAll()

        for dayOffset in 0..<14 {
            guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
            comps.hour = hour
            comps.minute = minute
            guard let fireDate = calendar.date(from: comps), fireDate > now else { continue }

            let triggerComps = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Chess 98"
            content.body = bodyProvider(dayOffset)
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(Self.dailyReminderIdentifierPrefix)\(dayOffset)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.dailyReminderIdentifierPrefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}

enum DailyReminderBody {
    /// Body text shown for a notification scheduled at `dayOffset` from
    /// today, given the most recent stats. Body is fixed at schedule time;
    /// we refresh via `rescheduleDailyReminders` whenever the app foregrounds.
    static func body(forDayOffset dayOffset: Int, stats: PlayerStats) -> String {
        if stats.currentStreak > 0 {
            if !stats.puzzlesSolvedToday {
                return "Today's puzzle is waiting — don't lose your \(stats.currentStreak)-day streak."
            }
            return "Don't lose your \(stats.currentStreak)-day streak — play a game."
        }
        return "The board is set. Come play."
    }
}
