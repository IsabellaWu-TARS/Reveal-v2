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
        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
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

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
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

    /// A day the user merely opened the app on (no favourite, no note) must
    /// open from the calendar and show its card.
    func testSeenDayOpensFromCalendar() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)
        app.buttons["Calendar"].firstMatch.tap()
        sleep(3)
        shot("80-calendar-seen")

        // October 21 sits in the same week row as today (22), one column left.
        let cell = app.coordinate(withNormalizedOffset: CGVector(dx: 0.388, dy: 0.617))
        cell.tap()
        sleep(3)
        shot("81-seen-day-sheet")
    }

    /// Launch → quit → launch again: the daily card must be the same one.
    func testDailyCardStableAcrossRelaunch() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(5)
        shot("70-card-first-launch")
        app.terminate()
        sleep(2)
        app.launch()
        sleep(5)
        shot("71-card-second-launch")
    }

    /// Opens Settings → Privacy Policy and captures the sheet, then scrolls to
    /// the retention and third-party sections.
    func testCapturePrivacyPolicy() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable {
            gear.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap()
        }
        sleep(2)

        let privacyRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Privacy Policy' OR label CONTAINS '隐私政策'")
        ).firstMatch

        var attempts = 0
        while attempts < 6 && !privacyRow.isHittable {
            app.swipeUp()
            sleep(1)
            attempts += 1
        }
        shot("90-settings-rows")
        XCTAssertTrue(privacyRow.waitForExistence(timeout: 5), "Privacy Policy row missing from Settings")
        privacyRow.tap()
        sleep(2)

        XCTAssertTrue(
            app.staticTexts["Privacy Policy"].waitForExistence(timeout: 8)
                || app.staticTexts["隐私政策"].waitForExistence(timeout: 2),
            "Privacy Policy sheet never opened"
        )
        sleep(1)
        shot("91-privacy-top")
        app.swipeUp()
        sleep(1)
        shot("92-privacy-mid")
        app.swipeUp()
        sleep(1)
        shot("93-privacy-bottom")
    }

    /// Long-press card → Share Verse → the system share sheet must preview the
    /// card PNG, not the app icon.
    func testShareSheetPreviewsCard() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
            .press(forDuration: 1.0)
        sleep(2)
        shot("95-share-options")

        let verseRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Share Verse' OR label CONTAINS '分享经文'")
        ).firstMatch
        XCTAssertTrue(verseRow.waitForExistence(timeout: 5), "Share Verse row missing")
        verseRow.tap()
        sleep(4)
        shot("96-share-sheet")
    }

    /// Settings → Contact Us icons/labels, and the end of the list where the
    /// dead band sat under the last card.
    func testCaptureSettingsContacts() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable {
            gear.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap()
        }
        sleep(2)

        app.swipeUp()
        sleep(1)
        shot("97-contact-card")

        app.swipeUp()
        app.swipeUp()
        sleep(1)
        shot("98-settings-bottom")
    }

    /// Calendar day sheet: full card, tap to flip to the reflection side.
    func testCalendarCardFlip() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        app.buttons["Calendar"].firstMatch.tap()
        sleep(3)

        // A day the app was opened on (seen), one column left of today.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.388, dy: 0.617)).tap()
        sleep(3)
        shot("99-calendar-card-front")

        // Flip it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        sleep(2)
        shot("99b-calendar-card-back")

        app.swipeUp()
        sleep(1)
        shot("99c-calendar-note")
    }

    /// Flip today's card and capture the reflection side; then restore English.
    /// The language is whatever the app is currently set to.
    func testCaptureChineseReflection() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(5)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        // Flip the card (front → back).
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(2)
        shot("89-zh-reflection")
    }

    /// Puts the app back to English after a Chinese capture run.
    func testRestoreEnglish() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)
        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable {
            gear.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap()
        }
        sleep(2)

        let menu = app.buttons.matching(
            NSPredicate(format: "label == '中文' OR label == 'English'")
        ).firstMatch
        if menu.waitForExistence(timeout: 4), menu.isHittable {
            menu.tap()
            sleep(1)
            let en = app.buttons["English"].firstMatch
            if en.waitForExistence(timeout: 3) { en.tap(); sleep(2) }
        }
        sleep(1)
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label == 'English'")).firstMatch.exists,
            "language did not switch back to English"
        )
    }

    /// Settings → Card Text Colour row.
    func testCaptureCardInkRow() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable { gear.tap() }
        else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap() }
        sleep(2)

        app.swipeUp(); sleep(1)
        shot("A1-settings-ink-row")
        app.swipeUp(); sleep(1)
        shot("A2-settings-tint-row")
    }

    /// The first-launch guide: four steps, one visible at a time.
    func testCaptureOnboardingGuide() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(5)

        shot("G1-guide-step1")
        for i in 2...4 {
            let next = app.buttons["Next"].firstMatch
            if next.waitForExistence(timeout: 4), next.isHittable {
                next.tap(); sleep(1)
                shot("G\(i)-guide-step\(i)")
            }
        }
        let start = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Get Started' OR label CONTAINS '开始体验'")
        ).firstMatch
        if start.waitForExistence(timeout: 4), start.isHittable { start.tap(); sleep(2) }
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

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
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

    /// Opens the in-app Sources & Licenses sheet and captures it, so the
    /// text layout / divider spacing after the Privacy Policy section was
    /// appended can be checked against the screen.
    func testCaptureAboutBibleSources() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 1.5), b.isHittable { b.tap(); sleep(1) }
        }

        // Settings (bottom-right).
        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable {
            gear.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap()
        }
        sleep(2)

        // The "About Bible Sources" row sits below Language; scroll until visible.
        let sourcesRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'About Bible' OR label CONTAINS '资料来源'")
        ).firstMatch

        var attempts = 0
        while attempts < 6 && !sourcesRow.isHittable {
            app.swipeUp()
            sleep(1)
            attempts += 1
        }

        XCTAssertTrue(sourcesRow.waitForExistence(timeout: 5), "About Bible Sources row not found in Settings")
        sourcesRow.tap()
        sleep(2)

        let titleEN = app.staticTexts["Sources & Licenses"]
        let titleZH = app.staticTexts["资料来源与版权声明"]
        XCTAssertTrue(
            titleEN.waitForExistence(timeout: 8) || titleZH.waitForExistence(timeout: 2),
            "About Bible Sources sheet never opened"
        )
        sleep(1)
        shot("70-about-bible-top")
        app.swipeUp()
        sleep(1)
        shot("71-about-bible-middle")
        app.swipeUp()
        sleep(1)
        shot("72-about-bible-privacy-section")
    }

    /// Opens the note editor (keyboard up) and captures it, so the overlay's
    /// width and keyboard insets can be checked against the screen edges.
    func testCaptureNoteEditor() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)

        for label in ["Next", "下一步", "Get Started", "Begin", "Continue", "Start", "开始", "开始使用", "Next", "Next", "Next"] {
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
