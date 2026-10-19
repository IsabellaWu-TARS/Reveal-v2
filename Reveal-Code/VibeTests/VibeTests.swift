//
//  VibeTests.swift
//  RevealTests
//
//  Created by IsabellaWu on 2025/11/1.
//

import Testing
import Foundation
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

    /// Every book in the cards must resolve to a USFM code, otherwise the
    /// chapter fetch in BiblePassageView silently dies.
    @Test @MainActor func everyBookHasUSFMCode() throws {
        let url = try #require(Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"))
        let cards = try JSONDecoder().decode([RevealCard].self, from: Data(contentsOf: url))

        let unresolved = Set(cards.filter { BibleAPIService.usfmCode(for: $0.book) == nil }.map(\.book))
        #expect(unresolved.isEmpty, "no USFM code for: \(unresolved)")
    }
}
