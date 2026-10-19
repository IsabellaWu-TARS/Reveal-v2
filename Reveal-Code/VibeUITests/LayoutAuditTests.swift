//
//  LayoutAuditTests.swift
//  VibeUITests
//
//  Walks all four pages and captures a screenshot of each, so layout problems
//  (clipped tabs, off-screen controls) can be seen instead of guessed.
//

import XCTest

final class LayoutAuditTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func tapSymbol(_ app: XCUIApplication, _ symbol: String, fallback: CGVector) {
        let button = app.buttons.matching(identifier: symbol).firstMatch
        if button.waitForExistence(timeout: 2), button.isHittable {
            button.tap()
        } else {
            app.coordinate(withNormalizedOffset: fallback).tap()
        }
        sleep(2)
    }

    func testCaptureAllPages() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        // onboarding, if this install is fresh
        for label in ["Get Started", "Begin", "Continue", "Start", "开始", "开始使用"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        shot("10-home")

        // Calendar (top-right)
        tapSymbol(app, "calendar", fallback: CGVector(dx: 0.86, dy: 0.182))
        shot("11-calendar")
        print("CALENDAR AX:\n\(app.debugDescription)")

        // Calendar section tabs
        for label in ["Favorites", "Notes"] {
            let t = app.buttons[label]
            if t.exists, t.isHittable { t.tap(); sleep(1); shot("12-calendar-\(label.lowercased())") }
        }

        // back to home via the back chevron
        tapSymbol(app, "chevron.left", fallback: CGVector(dx: 0.055, dy: 0.10))

        // Bible (top-left)
        tapSymbol(app, "book.fill", fallback: CGVector(dx: 0.142, dy: 0.182))
        shot("13-bible")

        tapSymbol(app, "chevron.left", fallback: CGVector(dx: 0.055, dy: 0.10))

        // Settings (bottom-right)
        tapSymbol(app, "gearshape.fill", fallback: CGVector(dx: 0.86, dy: 0.80))
        shot("14-settings")

        // settings is a scroll view; capture the bottom half too
        app.swipeUp()
        sleep(1)
        shot("15-settings-scrolled")
    }
}
