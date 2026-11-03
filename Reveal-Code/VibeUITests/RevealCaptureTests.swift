//
//  RevealCaptureTests.swift
//  VibeUITests
//
//  Drives the app to the Bible page and captures screenshots, so the passage
//  screen can be checked (and shown) without a human tapping around.
//
//  Run:
//    xcodebuild test -project Reveal.xcodeproj -scheme Reveal \
//      -destination 'platform=iOS Simulator,id=<UDID>' \
//      -only-testing:RevealUITests/RevealCaptureTests
//

import XCTest

final class RevealCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp(language: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        if let language { app.launchArguments += ["-AppLanguage", language] }
        app.launch()
        return app
    }

    /// Walks the first-run flow if it is showing: pick English, then tap the
    /// page — the guide has no Next button.
    private func dismissOnboarding(_ app: XCUIApplication) {
        let english = app.buttons["language-en"].firstMatch
        if english.waitForExistence(timeout: 4), english.isHittable {
            english.tap()
            usleep(800_000)
        }
        for _ in 0..<7 {
            guard app.buttons["Skip"].exists || app.buttons["跳过"].exists else { return }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            usleep(500_000)
        }
    }

    private func openBiblePage(_ app: XCUIApplication) {
        // The Bible button is the top-left corner button on the home screen.
        let bibleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'book'")).firstMatch
        if bibleButton.waitForExistence(timeout: 3), bibleButton.isHittable {
            bibleButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.142, dy: 0.182)).tap()
        }
    }

    private func attachScreenshot(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testBiblePageEnglish() throws {
        let app = makeApp()
        sleep(4)
        dismissOnboarding(app)
        openBiblePage(app)

        XCTAssertTrue(app.staticTexts["Full Chapter"].waitForExistence(timeout: 20), "Full Chapter section never appeared")
        print("AX TREE:\n\(app.debugDescription)")

        // The chapter list only exists once the fetch has landed. The view
        // scrolls itself to the card's verse, so don't assert on the count
        // chip at the top — it may be scrolled out of the viewport.
        let verses = app.otherElements["chapterVerses"]
        XCTAssertTrue(verses.waitForExistence(timeout: 25), "Chapter fetch never produced verses")
        sleep(1)
        attachScreenshot("01-bible-page-en")

        app.swipeUp()
        app.swipeUp()
        sleep(2)
        attachScreenshot("02-bible-page-en-scrolled")
    }

    func testBiblePageChinese() throws {
        let app = makeApp(language: "zh-Hans")
        sleep(4)
        dismissOnboarding(app)
        openBiblePage(app)

        XCTAssertTrue(app.staticTexts["整章经文"].waitForExistence(timeout: 20), "整章经文 section never appeared")
        let verses = app.otherElements["chapterVerses"]
        XCTAssertTrue(verses.waitForExistence(timeout: 25), "Chinese chapter fetch never produced verses")
        sleep(1)
        attachScreenshot("03-bible-page-zh")

        app.swipeUp()
        sleep(2)
        attachScreenshot("04-bible-page-zh-scrolled")
    }
}
