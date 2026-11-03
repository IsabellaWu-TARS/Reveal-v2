//
//  RevealCard.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct BilingualCardContent: Codable {
    let verse: String
    /// The 1919 text as printed, for readers who prefer the received form.
    /// Optional so older card files still decode.
    let verseTraditional: String?
    let question: String
    let action: String

    init(verse: String, verseTraditional: String? = nil, question: String, action: String) {
        self.verse = verse
        self.verseTraditional = verseTraditional
        self.question = question
        self.action = action
    }
}

struct RevealCard: Identifiable, Codable {
    let id: String
    let reference: String
    let book: String
    let chapter: Int
    let verse: Int
    let en: BilingualCardContent
    let zh: BilingualCardContent

    func verseText(language: String) -> String {
        guard language == "zh-Hans" else { return en.verse }
        if ScriptPreference.isTraditional, let traditional = zh.verseTraditional, !traditional.isEmpty {
            return traditional
        }
        return zh.verse.isEmpty ? en.verse : zh.verse
    }
    func questionText(language: String) -> String {
        language == "zh-Hans" ? (zh.question.isEmpty ? en.question : zh.question) : en.question
    }
    func actionText(language: String) -> String {
        language == "zh-Hans" ? zh.action : en.action
    }

    /// "Leviticus 23:22" / "利未记 23:22" — the cards store English book names,
    /// so Chinese mode used to show an English book name inside Chinese text.
    func referenceText(language: String) -> String {
        "\(BookNames.display(book, language: language)) \(chapter):\(verse)"
    }

    /// The same reference with its translation appended, for surfaces that
    /// need to state the text's provenance ("…, WEB" / "…，和合本").
    func referenceWithTranslation(language: String) -> String {
        language == "zh-Hans"
            ? "\(referenceText(language: language))，和合本"
            : "\(referenceText(language: language)), WEB"
    }
}

enum CardMirrorState: Int { case front, back }
