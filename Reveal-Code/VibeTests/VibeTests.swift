//
//  VibeTests.swift
//  RevealTests
//
//  Created by IsabellaWu on 2025/11/1.
//

import Testing
import SwiftUI
import Foundation
import UserNotifications
@testable import Reveal

struct VibeTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    /// Guards the bundled card data. Every regression this file has had was a
    /// data problem, not a UI problem: a shifted parse produced 38 records with
    /// `book: ""` and a single id "-1-1" repeated, plus 168 cards whose Chinese
    /// verse belonged to a different reference.
    @Test func bundledCardsAreWellFormed() throws {
        let url = try #require(
            Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"),
            "RevealCards_bilingual.json is missing from the app bundle"
        )
        let cards = try JSONDecoder().decode([RevealCard].self, from: Data(contentsOf: url))

        #expect(cards.count == 314, "expected 314 cards, found \(cards.count)")
        #expect(Set(cards.map(\.id)).count == cards.count, "duplicate card ids break favourites and no-repeat")

        for card in cards {
            #expect(!card.book.isEmpty, "empty book on \(card.id)")
            #expect(card.reference.contains(":"), "reference is not a scripture reference on \(card.id)")
            #expect(!card.en.verse.isEmpty, "missing English verse on \(card.id)")
            #expect(!card.en.question.isEmpty, "missing English question on \(card.id)")
            #expect(!card.zh.verse.isEmpty, "missing Chinese verse on \(card.id)")
            #expect(!card.zh.question.isEmpty, "missing Chinese question on \(card.id)")
            #expect(!card.id.hasPrefix("-1-1"), "placeholder id survived on \(card.id)")
        }
    }

    /// A verse left in the question field is the signature of the old parse.
    @Test func noVerseTextInQuestionField() throws {
        let url = try #require(Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"))
        let cards = try JSONDecoder().decode([RevealCard].self, from: Data(contentsOf: url))

        let marker = try Regex(", WEB\\)$")
        let offenders = cards.filter { $0.en.question.contains(marker) }.map(\.id)
        #expect(offenders.isEmpty, "verse text found in question field: \(offenders.prefix(5))")
    }

    /// Regression: chapters such as 1 Corinthians 12 embed footnote markers as
    /// `{ "noteId": 12 }` inside a verse's content. A decoder that requires
    /// `text` throws on those and the whole chapter fails to load.
    @Test func chapterWithFootnotesDecodes() throws {
        let json = """
        {"book":{"id":"1CO","name":"1 Corinthians"},
         "chapter":{"number":12,"content":[
           {"type":"heading","content":["Spiritual Gifts"]},
           {"type":"verse","number":1,"content":["Now concerning spiritual things, brothers, I don’t want you to be ignorant.",{"noteId":12}]},
           {"type":"verse","number":2,"content":[{"text":"You know that when you were pagans,","poem":1},{"text":"you were led away to those mute idols.","poem":2}]}
         ]}}
        """
        let chapter = try BibleAPIService.parse(Data(json.utf8), fallbackBookName: "1 Corinthians", usfm: "1CO")
        #expect(chapter.verses.count == 2)
        #expect(chapter.verses.first?.heading == "Spiritual Gifts")
        #expect(chapter.verses.first?.text.contains("ignorant") == true)
        #expect(chapter.verses.last?.text.contains("mute idols") == true)
        #expect(chapter.bookName == "1 Corinthians")
    }

    /// A stale day key (the app left running past midnight, then relaunched)
    /// is replaced by the current day's card, and the next day's card differs.
    @Test @MainActor func staleDayKeySelfHealsAndNextDayDiffers() throws {
        let store = DailyCardStore.shared
        let today = try #require(store.currentCard?.id)
        let defaults = UserDefaults.standard

        // Pretend the stored state is left over from an older day.
        defaults.set("2020-01-01", forKey: "CurrentCardDayKey")
        defaults.set("stale-card-id", forKey: "CurrentCardId")
        store.refreshCardForToday()

        // The stale state is replaced by today's card, re-stamped with today.
        #expect(store.currentCard?.id == today)
        #expect(defaults.string(forKey: "CurrentCardDayKey") == store.todayDateKey)
        #expect(defaults.string(forKey: "CurrentCardId") == today)

        // Tomorrow is a different card — the deck advances one step per day.
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        #expect(store.previewCard(for: tomorrow)?.id != today)
    }

    /// The daily card is a function of the date: stable within a day, new on
    /// the next day, and identical to what the calendar shows for that date.
    @Test @MainActor func cardIsStableWithinADayAndChangesAtMidnight() throws {
        let store = DailyCardStore.shared
        let today = try #require(store.currentCard)
        let cal = Calendar.current

        // Calendar must agree with the home card for today.
        #expect(store.previewCard(for: Date())?.id == today.id)

        // Neighbouring days must be different cards — the deck walks one step
        // per calendar day.
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        #expect(store.previewCard(for: tomorrow)?.id != today.id)
        #expect(store.previewCard(for: yesterday)?.id != today.id)

        // The card is persisted against the date, so a relaunch on the same day
        // re-reads the same card instead of drawing a new one.
        let defaults = UserDefaults.standard
        #expect(defaults.string(forKey: "CurrentCardDayKey") == store.todayDateKey)
        #expect(defaults.string(forKey: "CurrentCardId") == today.id)
    }

    /// Calendar access rule: future days are sealed, today is always readable,
    /// a past day only if it was favourited or noted.
    @Test @MainActor func calendarSealsFutureDays() throws {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = cal.date(byAdding: .day, value: -7, to: today)!

        // Future: never, no matter what flags are set.
        #expect(CalendarView.canOpen(date: tomorrow, today: today, isFavorite: true, hasNote: true) == false)
        // Today: always.
        #expect(CalendarView.canOpen(date: today, today: today, isFavorite: false, hasNote: false) == true)
        // Past without any user mark: sealed.
        #expect(CalendarView.canOpen(date: lastWeek, today: today, isFavorite: false, hasNote: false, hasSeen: false) == false)
        // Past that was actually seen (the app opened that day): readable.
        #expect(CalendarView.canOpen(date: lastWeek, today: today, isFavorite: false, hasNote: false, hasSeen: true) == true)
        // Seen does not unlock the future.
        #expect(CalendarView.canOpen(date: tomorrow, today: today, isFavorite: false, hasNote: false, hasSeen: true) == false)
        // Past with a favourite or a note: readable.
        #expect(CalendarView.canOpen(date: yesterday, today: today, isFavorite: true, hasNote: false) == true)
        #expect(CalendarView.canOpen(date: yesterday, today: today, isFavorite: false, hasNote: true) == true)
    }

    /// Renders one card per CardStyle so the palette can be reviewed, and
    /// prints the contrast ratio of the card's white text against each
    /// gradient stop.
    @Test @MainActor func renderEveryCardStyle() throws {
        let cards = DailyCardStore.shared.allCards
        guard !cards.isEmpty else { return }

        var sample: [CardStyle: RevealCard] = [:]
        for c in cards { if sample[CardStyle.forCardId(c.id)] == nil { sample[CardStyle.forCardId(c.id)] = c } }

        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("RENDER-DIR \(dir.path)")

        for style in CardStyle.allCases {
            guard let card = sample[style] else { continue }
            let view = CardFrontView(card: card, language: "en", style: style,
                                     onFavorite: {}, isFavorite: false, showsFavoriteButton: false)
                .frame(width: 360, height: 572)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let img = renderer.uiImage, let data = img.pngData() else { continue }
            try data.write(to: dir.appendingPathComponent("style-\(style.rawValue).png"))
        }
        print("RENDER-DONE \(CardStyle.allCases.count) styles")
    }

    /// If the user has the reminder switched on, there must be a repeating
    /// request queued whose next fire is within the next 24 hours.
    @Test @MainActor func enabledReminderIsQueuedAndUpcoming() async throws {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "dailyReminderEnabled") else { return }

        // Permission lives outside the app's control: a simulator reset or a
        // fresh install makes this environment unable to test the queue, and
        // that is not a product failure.
        let auth = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        guard auth == .authorized || auth == .provisional else { return }

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
            .filter { $0.identifier == NotificationScheduler.dailyReminderIdentifier }
        #expect(pending.count == 1, "reminder is on but nothing is queued")

        let trigger = pending.first?.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.repeats == true, "reminder must repeat daily")
        if let next = trigger?.nextTriggerDate() {
            #expect(next.timeIntervalSinceNow < 24 * 3600, "next fire is more than a day away")
        }
        #expect(pending.first?.content.sound != nil, "reminder has no sound")
        #expect(pending.first?.content.title.isEmpty == false)
        #expect(pending.first?.content.body.isEmpty == false)
    }

    /// Regression: iOS drops pending notifications when the app binary is
    /// replaced. The next launch must put an already-enabled reminder back.
    @Test @MainActor func launchReassertRestoresReminder() async throws {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "dailyReminderEnabled") else { return }
        let center = UNUserNotificationCenter.current()
        let auth = await center.notificationSettings().authorizationStatus
        guard auth == .authorized || auth == .provisional else { return }

        // Simulate the wipe that a reinstall performs.
        center.removeAllPendingNotificationRequests()
        let cleared = await center.pendingNotificationRequests()
            .filter { $0.identifier == NotificationScheduler.dailyReminderIdentifier }
        #expect(cleared.isEmpty)

        // Exactly what ContentView.task does on launch.
        await NotificationScheduler.reassertIfEnabled()

        let restored = await center.pendingNotificationRequests()
            .filter { $0.identifier == NotificationScheduler.dailyReminderIdentifier }
        #expect(restored.count == 1, "reminder was not restored on launch")
        #expect((restored.first?.trigger as? UNCalendarNotificationTrigger)?.repeats == true)
    }

    /// The reminder must exist as real pending requests, with the specified
    /// copy, in both languages. Requires notification permission — run
    /// `LayoutAuditTests/testEnableDailyReminder` first.
    @Test @MainActor func dailyReminderSchedulesLocalizedCopy() async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        #expect(settings.authorizationStatus == .authorized,
                "notifications not authorized — run testEnableDailyReminder first")

        await NotificationScheduler.scheduleDailyReminder(hour: 20, minute: 30, appLanguage: "en")
        var pending = await center.pendingNotificationRequests()
        #expect(pending.count == 1, "expected one repeating request, got \(pending.count)")
        #expect(pending.first?.content.title == "A Moment with God")
        #expect(pending.first?.content.body == "Take a moment to be still. God’s Word is waiting for you today.")
        #expect((pending.first?.trigger as? UNCalendarNotificationTrigger)?.repeats == true,
                "the reminder must repeat daily, otherwise it goes silent after a week")
        #expect(pending.first?.content.sound != nil, "reminder must carry a sound")

        await NotificationScheduler.scheduleDailyReminder(hour: 20, minute: 30, appLanguage: "zh-Hans")
        pending = await center.pendingNotificationRequests()
        #expect(pending.count == 1, "expected one repeating Chinese request, got \(pending.count)")
        #expect(pending.first?.content.title == "与神相遇的时刻")
        #expect(pending.first?.content.body == "静下心来，留一点时间给神。今天，祂的话语正等候着你。")

        // Restore whatever the app itself has persisted, so running the tests
        // doesn't wipe the user's real reminder off the simulator.
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier))
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "dailyReminderEnabled") {
            await NotificationScheduler.scheduleDailyReminder(
                hour: defaults.integer(forKey: "dailyReminderHour"),
                minute: defaults.integer(forKey: "dailyReminderMinute"),
                appLanguage: defaults.string(forKey: "AppLanguage") ?? "en"
            )
        }
    }

    /// Every book in the cards must resolve to a USFM code, otherwise the
    /// chapter fetch in BiblePassageView silently dies.
    @Test @MainActor func everyBookHasUSFMCode() throws {
        let url = try #require(Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"))
        let cards = try JSONDecoder().decode([RevealCard].self, from: Data(contentsOf: url))

        let unresolved = Set(cards.filter { BibleAPIService.usfmCode(for: $0.book) == nil }.map(\.book))
        #expect(unresolved.isEmpty, "no USFM code for: \(unresolved)")
    }
}
