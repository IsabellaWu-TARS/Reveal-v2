//
//  AppLocaleTests.swift
//  RevealTests
//
//  An English app on a Chinese phone rendered "十一月 2026": DateFormatter was
//  given a format but no locale, so "MMMM" resolved against the device. These
//  pin the formatter locale to the app's language instead.
//

import XCTest
@testable import Reveal

final class AppLocaleTests: XCTestCase {

    private func november() -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 8
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    private func formatted(_ language: String, _ format: String) -> String {
        let f = DateFormatter()
        f.locale = AppLocale.forLanguage(language)
        f.dateFormat = format
        return f.string(from: november())
    }

    func testEnglishMonthNeverRendersChinese() {
        XCTAssertEqual(formatted("en", "MMMM yyyy"), "November 2026")
        XCTAssertEqual(formatted("en", "MMMM d"), "November 8")
        XCTAssertEqual(formatted("en", "MMMM d, yyyy"), "November 8, 2026")
    }

    func testChineseMonthStaysChinese() {
        XCTAssertEqual(formatted("zh-Hans", "yyyy 年 M 月"), "2026 年 11 月")
        XCTAssertEqual(formatted("zh-Hans", "MMMM d, yyyy"), "十一月 8, 2026")
    }

    func testLocaleIdentifierMatchesLanguage() {
        XCTAssertEqual(AppLocale.forLanguage("en").identifier, "en_US")
        // Foundation canonicalises zh_Hans_CN to zh_CN; compare like for like.
        XCTAssertEqual(AppLocale.forLanguage("zh-Hans").identifier,
                       Locale(identifier: "zh_Hans_CN").identifier)
        XCTAssertEqual(AppLocale.identifier(for: "zh-Hans"), "zh-Hans")
        XCTAssertEqual(AppLocale.identifier(for: "en"), "en")
    }
}
