import Foundation
@preconcurrency import UserNotifications

/// Schedules the user's daily-verse reminder notifications.
///
/// Behaviour:
/// - At scheduling time we look up the verse for each of the next
///   `daysAhead` calendar days and schedule one `UNCalendarNotificationTrigger`
///   per day, each carrying the verse preview as its body.
/// - All IDs are deterministic (`reveal.daySpecific.<yyyy-MM-dd>`) so that
///   re-scheduling on the same day replaces the old request instead of
///   creating duplicates.
/// - The type is `@MainActor` because `UNUserNotificationCenter` mutates
///   shared state on the main thread and our callers (Settings UI) live
///   there too.
@MainActor
enum NotificationScheduler {

    // MARK: - Constants

    static let dailyReminderIdentifier           = "reveal.dailyReminder"
    private static let daySpecificReminderPrefix = "reveal.daySpecific."

    // MARK: - Setup

    static func configure() {
        // Reserved for future (UNUserNotificationCenter delegate wiring).
    }

    // MARK: - Authorization

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - Cancellation

    /// Cancels **all** notifications owned by this scheduler (both the
    /// legacy single-id reminder and every per-day preview).
    @MainActor static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        // P15 (round 2): the `getPendingNotificationRequests` callback is a
        // `@Sendable () -> Void` closure, so touching the @MainActor-isolated
        // `center` inside it triggers a Swift 6 actor-isolation warning.
        // The user wants zero UI / behaviour change, so we keep this method
        // synchronous (callers — Settings UI — are already on the main
        // actor) and hop back onto MainActor inside the closure to invoke
        // the removal. Net behaviour is identical to before.
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0 == dailyReminderIdentifier
                    || $0.hasPrefix(daySpecificReminderPrefix) }
            if !ids.isEmpty {
                Task { @MainActor in
                    center.removePendingNotificationRequests(withIdentifiers: ids)
                }
            }
        }
    }

    /// Convenience kept for existing call sites — identical to `cancelAll`
    /// for our purposes (the legacy id is always a subset of what we own).
    @MainActor static func cancelDailyReminder() {
        cancelAll()
    }

    // MARK: - Scheduling

    /// Schedule the daily reminder.
    ///
    /// One **repeating** calendar request (`repeats: true`) rather than a
    /// rolling queue of one-shot requests:
    ///   • a repeating trigger fires at the next matching hour:minute, so a
    ///     reminder enabled at 09:00 for 20:30 still fires *today*;
    ///   • it never expires — the old 7-day queue went silent after a week
    ///     unless the user reopened Settings;
    ///   • it survives app termination, so nothing has to re-schedule on launch.
    ///
    /// - Parameters:
    ///   - hour: 0–23 hour at which the reminder fires each day.
    ///   - minute: 0–59 minute at which the reminder fires each day.
    ///   - appLanguage: `"en"` or `"zh-Hans"`, used to pick the copy.
    static func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        appLanguage: String
    ) async {
        guard await requestAuthorizationIfNeeded() else { return }

        // Remove anything previously queued (including legacy per-day ids) so
        // changing the time replaces the reminder instead of stacking.
        await cancelAllOwnedAsync()

        let isZH = (appLanguage == "zh-Hans")
        let content = UNMutableNotificationContent()
        content.title = isZH ? "与神相遇的时刻" : "A Moment with God"
        content.body = isZH
            ? "静下心来，留一点时间给神。今天，祂的话语正等候着你。"
            : "Take a moment to be still. God’s Word is waiting for you today."
        content.sound = reminderSound()
        content.userInfo = ["language": appLanguage]

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// The bundled chime, or the system sound if the asset is missing.
    private static func reminderSound() -> UNNotificationSound {
        if Bundle.main.url(forResource: "reveal_chime", withExtension: "caf") != nil {
            return UNNotificationSound(named: UNNotificationSoundName("reveal_chime.caf"))
        }
        return .default
    }

    // MARK: - Helpers

    /// Async version of `cancelAll` — waits for the removal so callers
    /// that immediately follow up with `add(...)` can't race duplicates.
    private static func cancelAllOwnedAsync() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let ids = requests
            .map(\.identifier)
            .filter { $0 == dailyReminderIdentifier
                || $0.hasPrefix(daySpecificReminderPrefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
