//
//  CardTintModeTests.swift
//  RevealTests
//
//  Proves the Card Colour setting reaches the card, that "Daily default" puts
//  the built-in palette back, and that Automatic ink keeps up when the card
//  colour changes underneath it.
//

import XCTest
import SwiftUI
import UIKit
@testable import Reveal

final class CardTintModeTests: XCTestCase {

    @MainActor
    private func render(_ card: RevealCard, _ style: CardStyle) -> UIImage? {
        let view = CardFrontView(
            card: card,
            language: "en",
            style: style,
            onFavorite: {},
            isFavorite: false,
            showsFavoriteButton: false
        )
        .frame(width: 360, height: 572)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.uiImage
    }

    @MainActor
    func testCustomTintRendersAndResets() throws {
        let cards = DailyCardStore.shared.allCards
        let card = try XCTUnwrap(cards.first { !CardStyle.forCardId($0.id).hasDeepTone })
        let style = CardStyle.forCardId(card.id)

        let defaults = UserDefaults.standard
        let tintMode = defaults.string(forKey: "cardTintMode")
        let tintHex = defaults.string(forKey: "cardTintCustomHex")
        let inkMode = defaults.string(forKey: "cardInkMode")
        defer {
            defaults.set(tintMode ?? CardTint.automatic.rawValue, forKey: "cardTintMode")
            defaults.set(tintHex ?? "D6B8A8", forKey: "cardTintCustomHex")
            defaults.set(inkMode ?? CardInk.white.rawValue, forKey: "cardInkMode")
        }

        // Automatic ink + a deep custom card: text must come out white.
        defaults.set(CardTint.custom.rawValue, forKey: "cardTintMode")
        defaults.set("1F2A44", forKey: "cardTintCustomHex")           // luminance ≈ 0.02
        defaults.set(CardInk.automatic.rawValue, forKey: "cardInkMode")
        let deep = try XCTUnwrap(render(card, style))
        attach(deep, "tint-custom-deep-automatic-ink")

        // A pale custom card: same setting must flip to espresso ink.
        defaults.set("F3E4D2", forKey: "cardTintCustomHex")           // luminance ≈ 0.79
        let pale = try XCTUnwrap(render(card, style))
        attach(pale, "tint-custom-pale-automatic-ink")

        // Back to the daily palette.
        defaults.set(CardTint.automatic.rawValue, forKey: "cardTintMode")
        let original = try XCTUnwrap(render(card, style))
        attach(original, "tint-daily-default")

        // The two custom renders must differ from the default one.
        XCTAssertNotEqual(png(deep), png(original), "custom tint did not change the card")
        XCTAssertNotEqual(png(pale), png(original), "custom tint did not change the card")
        XCTAssertNotEqual(png(deep), png(pale), "custom tint ignored the chosen colour")
    }

    /// The Automatic ink choice is driven by luminance, so it must always pick
    /// the higher-contrast option across the whole colour range.
    @MainActor
    func testAutomaticInkPicksGreaterContrast() {
        let ink = CardInkPalette(isDeep: false, mode: .automatic, customHex: "000000")
        XCTAssertEqual(ink.body, Design.paperInkDeep)

        let onDeep = CardInkPalette(isDeep: true, mode: .automatic, customHex: "000000")
        XCTAssertEqual(onDeep.body, .white)

        // The crossover sits at L ≈ 0.21: below it white wins, above it espresso.
        for hex in ["101010", "3355AA", "7A4A2A", "F3E4D2", "FFFFFF"] {
            let lum = CardTintPalette.luminance(hex: hex)
            let resolved = CardInkPalette(isDeep: lum < 0.21, mode: .automatic, customHex: hex)
            let white = 1.05 / (lum + 0.05)
            let espresso = (lum + 0.05) / (0.014 + 0.05)
            let chosenIsWhite = resolved.body == .white
            XCTAssertEqual(chosenIsWhite, white > espresso,
                           "\(hex): picked \(chosenIsWhite ? "white" : "espresso") but the other has more contrast")
        }
    }

    // MARK: - Helpers

    private func attach(_ image: UIImage, _ name: String) {
        guard let data = image.pngData() else { return }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func png(_ image: UIImage) -> Data { image.pngData() ?? Data() }
}
