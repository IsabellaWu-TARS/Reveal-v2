//
//  ScriptSwitchCaptureTests.swift
//  RevealUITests
//
//  Captures the Simplified / Traditional switch in Settings and the card in
//  both renderings, so the difference can be seen on a running build.
//

import XCTest

final class ScriptSwitchCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func openSettings(_ app: XCUIApplication) {
        let gear = app.buttons.matching(identifier: "gearshape.fill").firstMatch
        if gear.waitForExistence(timeout: 3), gear.isHittable {
            gear.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.80)).tap()
        }
        sleep(2)
    }

    private func goHome(_ app: XCUIApplication) {
        // The header chevron on the settings page.
        let chevron = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'chevron' OR label CONTAINS '返回' OR label CONTAINS 'Back'")
        ).firstMatch
        if chevron.waitForExistence(timeout: 2), chevron.isHittable {
            chevron.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.09, dy: 0.08)).tap()
        }
        sleep(2)
    }

    func testCaptureScriptSwitch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppLanguage", "zh-Hans", "-HasLaunchedBefore", "YES"]
        app.launch()
        sleep(6)

        // Start from Simplified, whatever the previous run left behind.
        openSettings(app)
        let simplified = app.buttons["简体"].firstMatch
        XCTAssertTrue(simplified.waitForExistence(timeout: 6), "简体 segment not found in Settings")
        simplified.tap()
        sleep(2)
        attach("S2-settings-script")

        goHome(app)
        attach("S1-card-simplified")

        openSettings(app)
        let traditional = app.buttons["繁體"].firstMatch
        XCTAssertTrue(traditional.waitForExistence(timeout: 5), "繁體 segment not found in Settings")
        traditional.tap()
        sleep(2)

        goHome(app)
        attach("S4-card-traditional")

        // Leave the app as a new reader would find it.
        openSettings(app)
        if simplified.waitForExistence(timeout: 5), simplified.isHittable {
            simplified.tap()
            sleep(1)
        }
    }
}
