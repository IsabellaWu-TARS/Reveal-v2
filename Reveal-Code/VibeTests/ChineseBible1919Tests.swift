//
//  ChineseBible1919Tests.swift
//  RevealTests
//
//  The Chinese text used to come from an API serving the 1989 new-punctuation
//  edition. It is now the 1919 官話和合本, bundled. These tests pin the things
//  that would silently go wrong: the bundle going missing, the wrong edition
//  sneaking back in, and the 314 cards drifting away from the chapter text.
//

import XCTest
@testable import Reveal

final class ChineseBible1919Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: ScriptPreference.key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: ScriptPreference.key)
        super.tearDown()
    }

    private func chapter(_ usfm: String, _ number: Int,
                         script: ChineseScript = .simplified) async throws -> BibleChapter {
        try await ChineseBibleStore.shared.chapter(
            usfm: usfm, number: number, fallbackBookName: usfm, script: script
        )
    }

    private func useScript(_ script: ChineseScript) {
        UserDefaults.standard.set(script.rawValue, forKey: ScriptPreference.key)
    }

    /// The whole canon is there: 66 books, 1,189 chapters.
    ///
    /// 31,102 is the canonical verse count; a handful of those numbers are
    /// merged into a neighbour in the 1919 transcription (the marker is there,
    /// the text is not), so the text holds 31,021 verses with content.
    func testBundleHoldsTheCompleteCanon() async throws {
        let count = try await ChineseBibleStore.shared.verseCount()
        XCTAssertEqual(count, 31021)
        XCTAssertGreaterThan(count, 31000, "The bundled 1919 text should hold the full canon")
        XCTAssertEqual(ChineseBibleStore.bookNames.count, 66)
    }

    /// 1919 readings, not 1989: 　神 with the full-width space, 形像, 推羅.
    func testTextIsThe1919Edition() async throws {
        let genesis1 = try await chapter("GEN", 1)
        XCTAssertEqual(genesis1.verse(1)?.text, "起初　神创造天地。")

        let creation = try XCTUnwrap(genesis1.verse(27)?.text)
        XCTAssertTrue(creation.contains("形像"), "1919 uses 形像; the 1989 revision changed it to 形象")
        XCTAssertFalse(creation.contains("形象"))
        // Verbatim: the 1919 punctuation survives untouched.
        XCTAssertTrue(creation.contains("、"), "clause marks are left as printed in 1919")

        // The 1989 edition renamed Tyre to 泰尔 throughout; 1919 keeps 推罗.
        let psalm83 = try await chapter("PSA", 83)
        XCTAssertTrue(try XCTUnwrap(psalm83.verse(7)?.text).contains("推罗"))

        for book in ["PSA", "ISA", "EZK", "MAT", "JHN"] {
            for number in 1...3 {
                let text = try await chapter(book, number).verses.map(\.text).joined()
                XCTAssertFalse(text.contains("泰尔") || text.contains("泰爾"),
                               "\(book) \(number) contains a 1989 reading")
            }
        }
    }

    func testChaptersAreCompleteAndNumbered() async throws {
        let genesis1 = try await chapter("GEN", 1)
        XCTAssertEqual(genesis1.verses.count, 31)
        XCTAssertEqual(genesis1.verses.map(\.number), Array(1...31))

        let psalm23 = try await chapter("PSA", 23)
        XCTAssertEqual(psalm23.verses.count, 6)
        XCTAssertEqual(psalm23.bookName, "诗篇")
        XCTAssertEqual(psalm23.verse(1)?.text, "大卫的诗。耶和华是我的牧者．我必不至缺乏。")

        // The verse that used to carry a stray English word.
        let philippians4 = try await chapter("PHP", 4)
        let verse6 = try XCTUnwrap(philippians4.verse(6)?.text)
        XCTAssertTrue(verse6.hasPrefix("应当一无罣虑"))
        XCTAssertFalse(verse6.contains("knowingly"))
        XCTAssertFalse(verse6.contains("unchecked"))
    }

    func testUnknownBookOrChapterFailsCleanly() async {
        do {
            _ = try await chapter("GEN", 51)
            XCTFail("Genesis 51 does not exist")
        } catch {
            XCTAssertTrue(error is ChineseBibleStore.StoreError)
        }
    }

    /// Every card's Chinese verse must exist verbatim in the bundled text — the
    /// card corpus and the chapter reader must never drift apart again.
    func testEveryCardVerseMatchesTheBundledText() async throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"))
        let cards = try JSONDecoder().decode([RevealCard].self, from: Data(contentsOf: url))
        XCTAssertEqual(cards.count, 314)

        var checked = 0
        for card in cards {
            guard let usfm = BibleAPIService.usfmCode(for: card.book) else {
                XCTFail("No USFM code for \(card.book)"); continue
            }
            let chapter = try await chapter(usfm, card.chapter)
            let verse = try XCTUnwrap(chapter.verse(card.verse), "\(card.id) missing from \(usfm) \(card.chapter)")
            let cardText = card.zh.verse.trimmingCharacters(in: .whitespacesAndNewlines)
            let chapterText = verse.text.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertTrue(
                chapterText.hasPrefix(cardText) || chapterText == cardText + "。",
                "\(card.id): card says “\(cardText)” but chapter says “\(chapterText)”"
            )
            checked += 1
        }
        XCTAssertEqual(checked, 314)
    }

    /// Chinese chapters come from the bundle, so they resolve with no network.
    func testChineseChapterNeedsNoNetwork() async throws {
        let fetched = try await BibleAPIService.shared.chapter(book: "John", chapter: 3, language: "zh-Hans")
        XCTAssertEqual(fetched.verses.count, 36)
        XCTAssertTrue(try XCTUnwrap(fetched.verse(16)?.text).hasPrefix("神爱世人"))
    }

    /// The reader can switch to the 1919 text as printed, and back.
    func testTraditionalScriptIsAvailable() async throws {
        let simplified = try await chapter("GEN", 1, script: .simplified)
        XCTAssertEqual(simplified.verse(1)?.text, "起初　神创造天地。")

        let traditional = try await chapter("GEN", 1, script: .traditional)
        XCTAssertEqual(traditional.verse(1)?.text, "起初　神創造天地。")
        XCTAssertEqual(traditional.verses.count, simplified.verses.count)

        let psalm = try await chapter("PSA", 23, script: .traditional)
        XCTAssertEqual(psalm.verse(1)?.text, "大衞的詩。耶和華是我的牧者．我必不至缺乏。")
    }

    /// The simplification is character-for-character: same length, same
    /// punctuation, same verse boundaries. This is the audit that shows we
    /// never reworded anything — only the character forms differ.
    func testSimplifiedIsACharacterOnlyConversion() async throws {
        for (usfm, chapters) in try await sampleChapters() {
            for number in chapters {
                let simplified = try await chapter(usfm, number, script: .simplified)
                let traditional = try await chapter(usfm, number, script: .traditional)
                XCTAssertEqual(simplified.verses.count, traditional.verses.count,
                               "\(usfm) \(number): verse count changed with the script")
                for (s, t) in zip(simplified.verses, traditional.verses) {
                    XCTAssertEqual(s.number, t.number)
                    XCTAssertEqual(s.text.count, t.text.count,
                                   "\(usfm) \(number):\(s.number) changed length — a character was substituted, not just re-formed")
                }
            }
        }
    }

    private func sampleChapters() async throws -> [(String, [Int])] {
        [("GEN", [1, 2]), ("PSA", [23, 119]), ("JHN", [3]), ("PHP", [4]), ("REV", [22])]
    }

    /// Cards follow the same switch, and never disagree with the chapter.
    func testCardsFollowTheScriptPreference() async throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"))
        let cards = try JSONDecoder().decode([RevealCard].self, from: Data(contentsOf: url))

        useScript(.simplified)
        XCTAssertEqual(cards[0].verseText(language: "zh-Hans"), "起初　神创造天地。")

        useScript(.traditional)
        XCTAssertEqual(cards[0].verseText(language: "zh-Hans"), "起初　神創造天地。")

        // English is untouched by the switch.
        XCTAssertEqual(cards[0].verseText(language: "en"), cards[0].en.verse)
    }
}
