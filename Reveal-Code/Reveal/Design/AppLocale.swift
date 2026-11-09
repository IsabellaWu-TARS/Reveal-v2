//
//  AppLocale.swift
//  Reveal
//
//  One place that answers "which locale does the app's language map to".
//
//  The in-app language switch is not the system language, and Foundation's
//  date formatting follows the *device*: an English app on a Chinese phone was
//  rendering "十一月 2026" under an English calendar. Every formatter that prints
//  a date for the reader takes its locale from here.
//

import Foundation

enum AppLocale {
    static func forLanguage(_ language: String) -> Locale {
        language == "zh-Hans" ? Locale(identifier: "zh_Hans_CN") : Locale(identifier: "en_US")
    }

    static func identifier(for language: String) -> String {
        language == "zh-Hans" ? "zh-Hans" : "en"
    }
}
