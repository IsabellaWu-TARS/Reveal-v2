//
//  ScriptPreference.swift
//  Reveal
//
//  Traditional or simplified characters for the Chinese scripture.
//
//  The bundled text is the 1919 和合本 exactly as printed — traditional
//  characters, its own punctuation, its own archaic forms. The simplified
//  rendering is a character-for-character conversion of that same text, not a
//  revised edition: no word, name, punctuation mark or verse boundary changes.
//  Readers who want the received form can switch back at any time.
//

import Foundation

enum ChineseScript: String, CaseIterable, Identifiable {
    case simplified
    case traditional

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .simplified:  return language == "zh-Hans" ? "简体" : "Simplified"
        case .traditional: return language == "zh-Hans" ? "繁體" : "Traditional"
        }
    }
}

enum ScriptPreference {
    /// UserDefaults key, also read by `@AppStorage` in the views that draw text.
    static let key = "scriptPreference"

    static var current: ChineseScript {
        ChineseScript(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .simplified
    }

    static var isTraditional: Bool { current == .traditional }
}
