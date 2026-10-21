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

    /// Turns the daily reminder on so the app asks for notification
    /// permission, then grants it. Run before the unit test that inspects the
    /// pending notification requests.
    func testEnableDailyReminder() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Get Started", "Begin", "Continue", "Start", "开始", "开始使用"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        // Settings is the bottom-right corner button on the home screen.
        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable {
            gear.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap()
        }
        sleep(2)

        let toggle = app.switches.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "reminder toggle not found")

        // The reminder now persists, so make sure it ends up ON (one tap
        // schedules; a second would switch it back off).
        if (toggle.value as? String) != "1" {
            toggle.tap()
            sleep(1)
        }
        if (toggle.value as? String) != "1" {
            toggle.tap()
            sleep(2)
        }

        // System permission alert lives in SpringBoard.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow", "允许", "Allow Notifications", "允许通知"] {
            let allow = springboard.buttons[label]
            if allow.waitForExistence(timeout: 3), allow.isHittable {
                allow.tap()
                break
            }
        }
        sleep(1)
        shot("50-reminder-enabled")
    }

    /// Captures the launch screen mid-animation. Run once with the simulator in
    /// light appearance and once in dark (`xcrun simctl ui <udid> appearance …`).
    func testCaptureSplash() throws {
        let app = XCUIApplication()
        app.launch()
        // The splash pops at ~0.1s and lives ~2.3s; grab it while breathing.
        usleep(700_000)
        shot("40-splash")
    }

    /// Opens the share sheet from the home screen and captures it.
    func testCaptureShareOverlay() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Get Started", "Begin", "Continue", "Start", "开始", "开始使用"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        let share = app.buttons.matching(identifier: "square.and.arrow.up").firstMatch
        if share.waitForExistence(timeout: 3), share.isHittable {
            share.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.82)).tap()
        }

        XCTAssertTrue(app.staticTexts["Share"].waitForExistence(timeout: 10), "share sheet never opened")
        sleep(1)
        shot("30-share-overlay")
        print("SHARE OVERLAY: screen=\(app.windows.firstMatch.frame) title=\(app.staticTexts["Share"].frame)")

        // Picking an option must actually reach the system share sheet, not
        // just dismiss the overlay.
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Share Verse'")).firstMatch.tap()
        let activity = app.otherElements["ActivityListView"]
        let copyButton = app.buttons["Copy"]
        let appeared = activity.waitForExistence(timeout: 8) || copyButton.waitForExistence(timeout: 2)
        XCTAssertTrue(appeared, "system share sheet never appeared after choosing an option")
        sleep(3)   // let the image preview render in the sheet
        shot("31-share-system-sheet")
    }

    /// Opens the in-app privacy policy from Settings and captures it.
    /// App Store Review Guideline 5.1.1 requires a privacy-policy URL, and
    /// this sheet is the in-app counterpart a reviewer will look for.
    func testCapturePrivacyPolicy() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Get Started", "Begin", "Continue", "Start", "开始", "开始使用"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        // Settings is the bottom-right corner button on the home screen.
        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable {
            gear.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap()
        }
        sleep(2)

        // The Privacy Policy row sits below "About Bible Sources", so scroll
        // down until it is visible.
        let policyRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Privacy' OR label CONTAINS '隐私'")
        ).firstMatch

        var attempts = 0
        while attempts < 6 && !policyRow.isHittable {
            app.swipeUp()
            sleep(1)
            attempts += 1
        }

        XCTAssertTrue(policyRow.waitForExistence(timeout: 5), "privacy policy row not found in Settings")
        shot("60-settings-privacy-row")
        policyRow.tap()
        sleep(2)

        XCTAssertTrue(
            app.staticTexts["Privacy Policy"].waitForExistence(timeout: 8)
                || app.staticTexts["隐私政策"].waitForExistence(timeout: 2),
            "privacy policy sheet never opened"
        )
        sleep(1)
        shot("61-privacy-policy")
        app.swipeUp()
        sleep(1)
        shot("62-privacy-policy-scrolled")
    }

    /// Opens the note editor (keyboard up) and captures it, so the overlay's
    /// width and keyboard insets can be checked against the screen edges.
    func testCaptureNoteEditor() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Get Started", "Begin", "Continue", "Start", "开始", "开始使用"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        // The Notes pill sits at the bottom centre of the home screen.
        let pill = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'note'")).firstMatch
        if pill.waitForExistence(timeout: 3), pill.isHittable {
            pill.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.80)).tap()
        }

        XCTAssertTrue(app.staticTexts["My Reflection"].waitForExistence(timeout: 10), "note editor never opened")
        sleep(2)  // let the keyboard animate in
        shot("20-note-editor")

        // How wide is the card compared with the screen? Catches the
        // TextEditor-drives-ideal-width overflow.
        let screen = app.windows.firstMatch.frame
        let title = app.staticTexts["My Reflection"]
        let close = app.buttons.matching(identifier: "xmark.circle.fill").firstMatch
        let autoSave = app.staticTexts["Auto-saves"]
        print("NOTE EDITOR: screen=\(screen) title=\(title.frame) close=\(close.frame) autoSave=\(autoSave.frame) keyboard=\(app.keyboards.firstMatch.frame)")

        app.buttons.matching(identifier: "xmark.circle.fill").firstMatch.tap()
        sleep(1)
    }
}
