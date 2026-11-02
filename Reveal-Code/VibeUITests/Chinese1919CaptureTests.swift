//
//  Chinese1919CaptureTests.swift
//  RevealUITests
//
//  Captures the Chinese card and the Chinese chapter view so the 1919 text can
//  be inspected on a running build — the text now comes from the bundle, not
//  from the API.
//

import XCTest

final class Chinese1919CaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testCaptureChinese1919() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppLanguage", "zh-Hans", "-HasLaunchedBefore", "YES"]
        app.launch()
        sleep(6)

        attach("C1-home-card-zh")

        let bibleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'book'")).firstMatch
        if bibleButton.waitForExistence(timeout: 3), bibleButton.isHittable {
            bibleButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.142, dy: 0.182)).tap()
        }

        let verses = app.otherElements["chapterVerses"]
        XCTAssertTrue(verses.waitForExistence(timeout: 25), "Chinese chapter never rendered from the bundle")
        sleep(1)
        attach("C2-chapter-zh")

        app.swipeUp(); app.swipeUp()
        sleep(2)
        attach("C3-chapter-zh-scrolled")
    }
}
