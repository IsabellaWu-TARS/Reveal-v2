//
//  CardLayoutTests.swift
//  RevealTests
//
//  The card's type used to be fixed points. On a phone with Display Zoom on —
//  and in the friend's case, an iPhone 13 reporting a ~320pt wide screen — the
//  card shrank but 17pt verse text did not, so long English verses overflowed
//  while the denser Chinese sat there looking normal. These pin the scaling.
//

import XCTest
import SwiftUI
@testable import Reveal

final class CardLayoutTests: XCTestCase {

    func testVerseSizeFollowsCardWidth() {
        let wide = CardTypeScale(width: 402)
        let standard = CardTypeScale(width: 390)
        let zoomed = CardTypeScale(width: 320)

        XCTAssertEqual(standard.verse, 18.94, accuracy: 0.01, "390pt card sits at ~19pt after the one-step bump")
        XCTAssertGreaterThan(wide.verse, standard.verse)
        XCTAssertLessThan(zoomed.verse, standard.verse, "a zoomed screen must not get the full-size verse")
        XCTAssertLessThan(zoomed.horizontal, standard.horizontal, "margins scale with the card too")
    }

    func testTypeSizesStayWithinReadableBounds() {
        let tiny = CardTypeScale(width: 180)
        let huge = CardTypeScale(width: 900)

        XCTAssertEqual(tiny.verse, 13, accuracy: 0.01)
        XCTAssertEqual(huge.verse, 23, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(tiny.caption, 10)
        XCTAssertLessThanOrEqual(huge.reference, 15)
        XCTAssertGreaterThanOrEqual(tiny.horizontal, 16)
        XCTAssertLessThanOrEqual(huge.horizontal, 30)
    }

    /// The card clamps Dynamic Type rather than letting it grow without limit:
    /// it is a fixed-size artefact and the verse must stay inside it.
    func testCardClampsDynamicTypeRange() {
        let range = DynamicTypeSize.xSmall ... DynamicTypeSize.large
        XCTAssertTrue(range.contains(.large))
        XCTAssertFalse(range.contains(.accessibility3))
    }
}
