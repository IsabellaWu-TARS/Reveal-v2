//
//  CardInkModeTests.swift
//  RevealTests
//
//  Proves the Card Text Colour setting actually reaches the card: renders the
//  same card in every mode and attaches each face to the result bundle.
//

import XCTest
import SwiftUI
import UIKit
@testable import Reveal

final class CardInkModeTests: XCTestCase {

    @MainActor
    func testEveryInkModeRenders() throws {
        let cards = DailyCardStore.shared.allCards
        // A pale card, the case that motivated the setting.
        guard let card = cards.first(where: { CardStyle.forCardId($0.id).hasDeepTone == false }),
              let deep = cards.first(where: { CardStyle.forCardId($0.id).hasDeepTone }) else {
            XCTFail("no cards loaded"); return
        }

        let defaults = UserDefaults.standard
        let originalMode = defaults.string(forKey: "cardInkMode")
        let originalHex = defaults.string(forKey: "cardInkCustomHex")
        defer {
            defaults.set(originalMode ?? CardInk.automatic.rawValue, forKey: "cardInkMode")
            defaults.set(originalHex ?? "FFFFFF", forKey: "cardInkCustomHex")
        }

        let cases: [(CardInk, String)] = [
            (.automatic, "automatic"),
            (.white, "white"),
            (.ink, "ink"),
            (.custom, "custom")
        ]

        for (mode, name) in cases {
            defaults.set(mode.rawValue, forKey: "cardInkMode")
            defaults.set("C0392B", forKey: "cardInkCustomHex")   // warm red for the custom case

            for (label, subject) in [("light", card), ("deep", deep)] {
                let view = CardFrontView(
                    card: subject,
                    language: "en",
                    style: CardStyle.forCardId(subject.id),
                    onFavorite: {},
                    isFavorite: false,
                    showsFavoriteButton: false
                )
                .frame(width: 360, height: 572)

                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                guard let image = renderer.uiImage, let data = image.pngData() else {
                    XCTFail("render failed: \(name)/\(label)"); continue
                }
                let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
                a.name = "ink-\(name)-\(label)"
                a.lifetime = .keepAlways
                add(a)
            }
        }
    }
}
