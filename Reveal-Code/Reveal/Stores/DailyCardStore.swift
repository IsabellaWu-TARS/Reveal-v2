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

    private var seededRNG: SeededRNG = SeededRNG(seed: 1)
    private var seed: UInt64 = 0
    private var currentIndex: Int = 0

    /// Returns the date that `todayDateKey` was last refreshed to. Used by
    /// `refreshIfDayChanged()` to detect when the calendar date has rolled
    /// past midnight even though the app stayed running in the background.
    private var lastRefreshDateKey: String = ""

    private init() {
        todayDateKey = Self.todayDateKey()
        lastRefreshDateKey = todayDateKey
        seed = Self.dailySeed()
        seededRNG = SeededRNG(seed: seed)
        appLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
        loadFavorites()
        loadViewedDates()
        allCards = Self.loadCards()
        advanceToTodayCard()
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
        seed = Self.dailySeed()
        seededRNG = SeededRNG(seed: seed)
        advanceToTodayCard()
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

    private func advanceToTodayCard() {
        guard !allCards.isEmpty else { return }
        if seenCardIds.count >= allCards.count {
            seenCardIds.removeAll()
            seed = Self.dailySeed()
            seededRNG = SeededRNG(seed: seed)
        }
        var gen = seededRNG
        let unseenIndices = allCards.indices.filter { !seenCardIds.contains(allCards[$0].id) }
        guard !unseenIndices.isEmpty else { return }
        let idx = unseenIndices[Int.random(in: 0..<unseenIndices.count, using: &gen)]
        currentCard = allCards[idx]
        seenCardIds.insert(allCards[idx].id)
        currentIndex = idx
        mirrorState = .front
        transitionAngle = 0
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

    func nextCard() {
        advanceToTodayCard()
    }

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

    private static func dailySeed() -> UInt64 {
        let dateStr = todayDateKey()
        var h = dateStr.hashValue
        if h < 0 { h = -h }
        return h == 0 ? 1 : UInt64(h)
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
        // Use a temporary RNG whose seed derives from the target date.
        let dateStr = Self.dateKey(for: date)
        var h = dateStr.hashValue
        if h < 0 { h = -h }
        let targetSeed = h == 0 ? 1 : UInt64(h)
        var rng = SeededRNG(seed: targetSeed)
        let idx = Int.random(in: 0..<allCards.count, using: &rng)
        return allCards[idx]
    }

    var totalCards: Int { allCards.count }
}
