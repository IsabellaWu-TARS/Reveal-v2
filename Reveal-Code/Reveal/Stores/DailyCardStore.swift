//
//  DailyCardStore.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class DailyCardStore: ObservableObject {
    static let shared = DailyCardStore()

    @Published private(set) var todayDateKey: String = ""
    @Published private(set) var currentCard: RevealCard?
    @Published private(set) var mirrorState: CardMirrorState = .front
    @Published private(set) var transitionAngle: Double = 0
    @Published private(set) var appLanguage: String = "en"
    @Published private(set) var allCards: [RevealCard] = []
    @Published private(set) var seenCardIds: Set<String> = []
    @Published private(set) var favoriteIds: Set<String> = []
    // BUG FIX (P0-3): Track which yyyy-MM-dd dates the user has actually opened
    // the home screen on, so the calendar can accurately mark days with scripture.
    @Published private(set) var viewedDates: Set<String> = []

    private var currentIndex: Int = 0

    /// Returns the date that `todayDateKey` was last refreshed to. Used by
    /// `refreshIfDayChanged()` to detect when the calendar date has rolled
    /// past midnight even though the app stayed running in the background.
    private var lastRefreshDateKey: String = ""

    private init() {
        todayDateKey = Self.todayDateKey()
        lastRefreshDateKey = todayDateKey
        appLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
        loadFavorites()
        loadViewedDates()
        allCards = Self.loadCards()
        refreshCardForToday()
        observeMidnight()
    }

    func setLanguage(_ language: String) {
        appLanguage = language
        UserDefaults.standard.set(language, forKey: "AppLanguage")
    }

    /// BUG FIX (P2-1): Refresh today's card if the calendar day has changed
    /// (e.g. user opened the app at 11pm, kept it in the background, and
    /// reopened at 12:30am). Before this, the same card was still being shown
    /// even though "today" was different and the seeded RNG should yield a
    /// different verse.
    func refreshIfDayChanged() {
        let currentKey = Self.todayDateKey()
        guard currentKey != lastRefreshDateKey else { return }
        todayDateKey = currentKey
        lastRefreshDateKey = currentKey
        refreshCardForToday()
    }

    /// Swap the card when the calendar day rolls over while the app is open.
    private func observeMidnight() {
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshCardForToday() }
        }
    }

    /// Mark the current date as viewed (called from HomeView.onAppear).
    /// Idempotent — safe to call on every appearance.
    func markTodayViewed() {
        refreshIfDayChanged()
        let key = Self.todayDateKey()
        guard !viewedDates.contains(key) else { return }
        viewedDates.insert(key)
        saveViewedDates()
    }

    /// True when the given date has a scripture card the user has seen.
    func hasScripture(for date: Date) -> Bool {
        viewedDates.contains(Self.dateKey(for: date))
    }

    /// Shows the card for **today**, and keeps showing it until the calendar
    /// day rolls over.
    ///
    /// The card is derived from the date itself, not from a random draw, so:
    ///   • reopening the app on the same day never changes the card;
    ///   • at midnight the day key changes and the next card is shown;
    ///   • every install sees the same card on the same date.
    ///
    /// The deck is walked in a fixed shuffled order, so a card
    /// only repeats after every card has been used.
    func refreshCardForToday() {
        guard !allCards.isEmpty else { return }

        let key = Self.todayDateKey()
        todayDateKey = key
        lastRefreshDateKey = key

        // Same day, and the stored card still exists → nothing to do.
        let defaults = UserDefaults.standard
        if defaults.string(forKey: Self.cardDayKeyDefaultsKey) == key,
           let storedId = defaults.string(forKey: Self.cardIdDefaultsKey),
           let idx = allCards.firstIndex(where: { $0.id == storedId }) {
            currentCard = allCards[idx]
            currentIndex = idx
            mirrorState = .front
            return
        }

        // New day (or first launch): pick the card for this date.
        let idx = Self.cardIndex(forDayKey: key, count: allCards.count)
        currentCard = allCards[idx]
        currentIndex = idx
        seenCardIds.insert(allCards[idx].id)
        defaults.set(key, forKey: Self.cardDayKeyDefaultsKey)
        defaults.set(allCards[idx].id, forKey: Self.cardIdDefaultsKey)
        mirrorState = .front
        transitionAngle = 0
    }

    // MARK: - Date → card

    private static let cardDayKeyDefaultsKey = "CurrentCardDayKey"
    private static let cardIdDefaultsKey = "CurrentCardId"

    /// Fixed deck order: a permutation of 0..<count built from a constant
    /// seed, computed once per card count. Walking it by day ordinal means a
    /// card never repeats until every card has been shown.
    private static let deckSeed: UInt64 = 0x5EED_0BEE_F00D_1234
    private static var deckCache: [Int] = []
    private static var deckCacheCount = 0

    private static func deck(count: Int) -> [Int] {
        if deckCacheCount == count, deckCache.count == count { return deckCache }
        var rng = SeededRNG(seed: deckSeed)
        deckCache = Array(0..<count).shuffled(using: &rng)
        deckCacheCount = count
        return deckCache
    }

    /// Number of days since 2001-01-01 for a `yyyy-MM-dd` key. Stable across
    /// launches and time zones because it is built from the key itself.
    private static func dayOrdinal(forDayKey key: String) -> Int {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: key) else { return 0 }
        var g = Calendar(identifier: .gregorian)
        g.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let days = g.dateComponents([.day], from: Date(timeIntervalSince1970: 978_307_200), to: date).day ?? 0
        return max(0, days)
    }

    /// Deterministic deck position for a day key.
    private static func cardIndex(forDayKey key: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let ordinal = dayOrdinal(forDayKey: key)
        return deck(count: count)[ordinal % count]
    }

    func flip() {
        HapticManager.soft()
        withAnimation(Design.springAnim) {
            mirrorState = mirrorState == .front ? .back : .front
            transitionAngle += 180
        }
    }

    func toggleFavorite(_ cardId: String) {
        HapticManager.success()
        if favoriteIds.contains(cardId) { favoriteIds.remove(cardId) }
        else { favoriteIds.insert(cardId) }
        saveFavorites()
    }

    func isFavorite(_ cardId: String) -> Bool { favoriteIds.contains(cardId) }

    private func loadFavorites() {
        favoriteIds = Set(UserDefaults.standard.stringArray(forKey: "FavoriteCardIds") ?? [])
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: "FavoriteCardIds")
    }

    private func loadViewedDates() {
        viewedDates = Set(UserDefaults.standard.stringArray(forKey: "ViewedDates") ?? [])
    }

    private func saveViewedDates() {
        UserDefaults.standard.set(Array(viewedDates), forKey: "ViewedDates")
    }

    private static func dateKey(for date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    var isFront: Bool { mirrorState == .front }

    private static func todayDateKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }


    private static func loadCards() -> [RevealCard] {
        guard let url = Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cards = try? JSONDecoder().decode([RevealCard].self, from: data) else { return [] }
        return cards
    }

    func cardForOnboarding(at index: Int) -> RevealCard? {
        guard !allCards.isEmpty else { return nil }
        return allCards[index % allCards.count]
    }

    /// Compute what the daily card will be for a given date (defaults to
    /// tomorrow, used by the daily-reminder notification to preview the
    /// next verse). Independent of the in-memory seenCardIds set so it
    /// doesn't pollute the current run.
    func previewCard(for date: Date) -> RevealCard? {
        guard !allCards.isEmpty else { return nil }
        // Same rule as today's card, so the calendar shows exactly the card the
        // user got on that date (and today matches the home screen).
        let key = Self.dateKey(for: date)
        return allCards[Self.cardIndex(forDayKey: key, count: allCards.count)]
    }

    var totalCards: Int { allCards.count }
}
