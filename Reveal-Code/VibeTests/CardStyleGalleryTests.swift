//
//  CardStyleGalleryTests.swift
//  RevealTests
//
//  Renders one card face per CardStyle and attaches each PNG to the result
//  bundle, so the palette can be reviewed (and contrast measured) without
//  shipping any gallery screen in the app.
//

import XCTest
import SwiftUI
import UIKit
@testable import Reveal

final class CardStyleGalleryTests: XCTestCase {

    @MainActor
    func testRenderEveryCardStyle() throws {
        let cards = DailyCardStore.shared.allCards
        XCTAssertFalse(cards.isEmpty, "no cards loaded")

        var sample: [CardStyle: RevealCard] = [:]
        for c in cards {
            let style = CardStyle.forCardId(c.id)
            if sample[style] == nil { sample[style] = c }
        }

        for style in CardStyle.allCases {
            guard let card = sample[style] else {
                XCTFail("no card sampled for \(style.rawValue)")
                continue
            }
            let face = CardFrontView(
                card: card,
                language: "en",
                style: style,
                onFavorite: {},
                isFavorite: false,
                showsFavoriteButton: false
            )
            .frame(width: 360, height: 572)

            let back = CardBackView(
                card: card,
                language: "en",
                style: style,
                onFavorite: {},
                isFavorite: false,
                showsFavoriteButton: false,
                showsReturnHint: false
            )
            .frame(width: 360, height: 572)

            for (suffix, view) in [("front", AnyView(face)), ("back", AnyView(back))] {
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                guard let image = renderer.uiImage, let data = image.pngData() else {
                    XCTFail("render failed for \(style.rawValue) \(suffix)")
                    continue
                }
                let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
                attachment.name = "style-\(style.rawValue)-\(suffix)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
}
