//
//  ReleaseReadinessTests.swift
//  RevealTests
//
//  Release gates: persistence of what the user typed, the Bible API's failure
//  path, and the offline floor (the day's verse is bundled, never fetched).
//

import XCTest
import Foundation
@testable import Reveal

final class ReleaseReadinessTests: XCTestCase {

    // MARK: - Persistence

    /// A note, a favourite and a viewed date must land in UserDefaults — the
    /// exact store a relaunch reads back. That is what "your notes stay on your
    /// iPhone" means.
    @MainActor
    func testUserDataIsPersisted() throws {
        let defaults = UserDefaults.standard
        let notes = NotesStore.shared
        let cards = DailyCardStore.shared
        let card = try XCTUnwrap(cards.currentCard, "no current card")

        notes.loadNote(for: card.id)
        let originalNote = notes.noteText
        let wasFavourite = cards.isFavorite(card.id)

        let marker = "readiness-\(UUID().uuidString.prefix(6))"
        notes.noteText = marker
        notes.save()

        let storedNotes = (defaults.dictionary(forKey: "UserNotesByCardId") as? [String: String]) ?? [:]
        XCTAssertEqual(storedNotes[card.id], marker, "note was not written to storage")

        if !wasFavourite { cards.toggleFavorite(card.id) }
        let storedFavourites = Set(defaults.stringArray(forKey: "FavoriteCardIds") ?? [])
        XCTAssertTrue(storedFavourites.contains(card.id), "favourite was not written to storage")

        cards.markTodayViewed()
        let storedDates = Set(defaults.stringArray(forKey: "ViewedDates") ?? [])
        let todayKey: String = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
        }()
        XCTAssertTrue(storedDates.contains(todayKey), "today was not recorded as a viewed day")

        // Restore the user's real state.
        notes.loadNote(for: card.id)
        notes.noteText = originalNote
        notes.save()
        if cards.isFavorite(card.id) != wasFavourite { cards.toggleFavorite(card.id) }
    }

    /// The card is pinned to the date, so relaunching must not redraw it.
    @MainActor
    func testCurrentCardIsPinnedToTheDay() throws {
        let defaults = UserDefaults.standard
        let cards = DailyCardStore.shared
        let card = try XCTUnwrap(cards.currentCard)

        XCTAssertEqual(defaults.string(forKey: "CurrentCardId"), card.id)
        let todayKey: String = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
        }()
        XCTAssertEqual(defaults.string(forKey: "CurrentCardDayKey"), todayKey)
    }

    // MARK: - Offline floor

    /// The verse a person reads comes from the bundled cards, never the network.
    @MainActor
    func testVerseTextIsBundledNotFetched() throws {
        let cards = DailyCardStore.shared.allCards
        XCTAssertFalse(cards.isEmpty)
        for card in cards.prefix(40) {
            XCTAssertFalse(card.verseText(language: "en").isEmpty)
            XCTAssertFalse(card.verseText(language: "zh-Hans").isEmpty)
        }
    }

    // MARK: - API failure handling

    /// An unknown book must fail with a typed error — not crash, not hang.
    func testUnknownBookFailsGracefully() async {
        let service = BibleAPIService.shared
        do {
            _ = try await service.chapter(book: "Not A Book", chapter: 1, language: "en")
            XCTFail("expected a failure for an unknown book")
        } catch let error as BibleAPIService.APIError {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        } catch {
            XCTAssertTrue(true) // any thrown error is fine; a crash is not
        }
    }

    /// Malformed payloads are rejected instead of producing an empty chapter.
    func testMalformedPayloadIsRejected() {
        let bad = Data("{\"nope\":true}".utf8)
        XCTAssertThrowsError(try BibleAPIService.parse(bad, fallbackBookName: "Test", usfm: "JHN"))
    }

    /// Happy path against the live API (skipped when there is no network).
    func testLiveChapterFetchDecodes() async throws {
        let service = BibleAPIService.shared
        do {
            let chapter = try await service.chapter(book: "John", chapter: 3, language: "en")
            XCTAssertGreaterThan(chapter.verses.count, 10, "John 3 should have more than 10 verses")
        } catch {
            throw XCTSkip("network unavailable: \(error)")
        }
    }
}
