import Foundation
import UserNotifications

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
    private static let previewCharLimit: Int     = 110

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

    /// Schedule the daily reminder. The notification body shows the
    /// verse preview for each target calendar day, so opening the
    /// notification feels meaningful instead of a generic nudge.
    ///
    /// - Parameters:
    ///   - hour: 0–23 hour at which the reminder fires each day.
    ///   - minute: 0–59 minute at which the reminder fires each day.
    ///   - appLanguage: `"en"` or `"zh-Hans"`, used to pick verse + body text.
    ///   - daysAhead: how many days into the future to schedule (default 7).
    static func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        appLanguage: String,
        daysAhead: Int = 7
    ) async {
        guard await requestAuthorizationIfNeeded() else { return }

        // Always start by removing any old per-day previews so we don't
        // stack duplicates when the user changes their reminder time.
        await cancelAllOwnedAsync()

        let isZH = (appLanguage == "zh-Hans")
        let title = isZH ? "今日经文 · 默想" : "Today's Verse · Reflection"
        let previewIntro = isZH ? "明日经文：" : "Tomorrow's verse: "

        let calendar = Calendar.current
        let center = UNUserNotificationCenter.current()

        for offset in 1...max(1, daysAhead) {
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            // P15: wrap the @MainActor-isolated `DailyCardStore.shared` read
            // in `MainActor.assumeIsolated` to silence the Swift 6 actor-
            // isolation warning. We're already on the main actor (the whole
            // `NotificationScheduler` enum is `@MainActor`), so this is
            // purely a hint to the compiler — runtime behaviour is
            // identical.
            guard let card = MainActor.assumeIsolated({ DailyCardStore.shared.previewCard(for: targetDate) }) else { continue }
            await scheduleOne(
                date: targetDate,
                hour: hour,
                minute: minute,
                title: title,
                body: previewIntro + trimmed(card.verseText(language: appLanguage)),
                cardId: card.id,
                language: appLanguage,
                center: center,
                calendar: calendar
            )
        }
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

    private static func scheduleOne(
        date: Date,
        hour: Int,
        minute: Int,
        title: String,
        body: String,
        cardId: String,
        language: String,
        center: UNUserNotificationCenter,
        calendar: Calendar
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["cardId": cardId, "language": language]

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: date, calendar: calendar),
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Skip this date; continue scheduling the rest.
        }
    }

    /// Deterministic id — same date → same id, so re-scheduling replaces
    /// the existing request rather than duplicating it.
    private static func identifier(for date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year  ?? 0
        let m = comps.month ?? 0
        let d = comps.day   ?? 0
        return String(format: "%@%04d-%02d-%02d", daySpecificReminderPrefix, y, m, d)
    }

    private static func trimmed(_ text: String) -> String {
        guard text.count > previewCharLimit else { return text }
        return String(text.prefix(previewCharLimit)) + "…"
    }
}
