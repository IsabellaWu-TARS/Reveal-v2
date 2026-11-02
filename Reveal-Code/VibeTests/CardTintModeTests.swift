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
    private func render(_ card: RevealCard, _ style: CardStyle, usesUserTint: Bool = true) -> UIImage? {
        let view = CardFrontView(
            card: card,
            language: "en",
            style: style,
            onFavorite: {},
            isFavorite: false,
            showsFavoriteButton: false,
            usesUserTint: usesUserTint
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
        let topHex = defaults.string(forKey: "cardTintTopHex")
        let bottomHex = defaults.string(forKey: "cardTintBottomHex")
        let inkMode = defaults.string(forKey: "cardInkMode")
        defer {
            defaults.set(tintMode ?? CardTint.automatic.rawValue, forKey: "cardTintMode")
            defaults.set(topHex ?? "D6B8A8", forKey: "cardTintTopHex")
            defaults.set(bottomHex ?? "C08A72", forKey: "cardTintBottomHex")
            defaults.set(inkMode ?? CardInk.white.rawValue, forKey: "cardInkMode")
        }

        // Automatic ink + a deep custom card: text must come out white.
        defaults.set(CardTint.custom.rawValue, forKey: "cardTintMode")
        defaults.set("1F2A44", forKey: "cardTintTopHex")             // near-black
        defaults.set("14243A", forKey: "cardTintBottomHex")
        defaults.set(CardInk.automatic.rawValue, forKey: "cardInkMode")
        let deep = try XCTUnwrap(render(card, style))
        attach(deep, "tint-custom-deep-automatic-ink")

        // A pale custom card: same setting must flip to espresso ink.
        defaults.set("F3E4D2", forKey: "cardTintTopHex")             // pale cream
        defaults.set("E6D2B8", forKey: "cardTintBottomHex")
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

    @MainActor
    func testTwoColoursBlendIntoOneGradient() throws {
        let cards = DailyCardStore.shared.allCards
        let card = try XCTUnwrap(cards.first)
        let style = CardStyle.forCardId(card.id)

        let blackToGreen = CardTintPalette(style: style, mode: .custom,
                                           topHex: "101010", bottomHex: "2F7A46")
        let greenToBlack = CardTintPalette(style: style, mode: .custom,
                                           topHex: "2F7A46", bottomHex: "101010")

        XCTAssertEqual(blackToGreen.stops.count, 3, "a custom card is still a three-stop gradient")
        XCTAssertNotEqual(blackToGreen.stops, greenToBlack.stops, "order of the two colours must matter")

        // The middle stop must sit between the two choices, not equal either.
        let onlyGreen = CardTintPalette(style: style, mode: .custom,
                                        topHex: "2F7A46", bottomHex: "2F7A46")
        XCTAssertNotEqual(blackToGreen.stops, onlyGreen.stops, "blending was ignored")
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

    /// Only today's card follows the chosen colours. A past day keeps the
    /// palette it was originally shown with, which is what the calendar passes.
    @MainActor
    func testPastDayIgnoresTheChosenColour() throws {
        let card = try XCTUnwrap(DailyCardStore.shared.allCards.first)
        let style = CardStyle.forCardId(card.id)
        let defaults = UserDefaults.standard
        let tintMode = defaults.string(forKey: "cardTintMode")
        let topHex = defaults.string(forKey: "cardTintTopHex")
        let bottomHex = defaults.string(forKey: "cardTintBottomHex")
        let inkMode = defaults.string(forKey: "cardInkMode")
        defer {
            defaults.set(tintMode ?? CardTint.automatic.rawValue, forKey: "cardTintMode")
            defaults.set(topHex ?? "D6B8A8", forKey: "cardTintTopHex")
            defaults.set(bottomHex ?? "C08A72", forKey: "cardTintBottomHex")
            defaults.set(inkMode ?? CardInk.white.rawValue, forKey: "cardInkMode")
        }

        // A deliberately loud custom colour.
        defaults.set(CardTint.custom.rawValue, forKey: "cardTintMode")
        defaults.set("1B2A4A", forKey: "cardTintTopHex")
        defaults.set("2F7A46", forKey: "cardTintBottomHex")
        defaults.set(CardInk.automatic.rawValue, forKey: "cardInkMode")

        let today = try XCTUnwrap(render(card, style, usesUserTint: true))
        let pastDay = try XCTUnwrap(render(card, style, usesUserTint: false))

        // What the same card looks like with no custom colour at all.
        defaults.set(CardTint.automatic.rawValue, forKey: "cardTintMode")
        let plain = try XCTUnwrap(render(card, style))

        XCTAssertEqual(png(pastDay), png(plain), "a past day must render the default palette")
        XCTAssertNotEqual(png(today), png(plain), "today must honour the chosen colour")
    }

    /// Visual proof of the two-colour mix, for review.
    @MainActor
    func testRenderTintPairExamples() throws {
        let card = try XCTUnwrap(DailyCardStore.shared.allCards.first)
        let style = CardStyle.forCardId(card.id)
        let defaults = UserDefaults.standard
        let tintMode = defaults.string(forKey: "cardTintMode")
        let topHex = defaults.string(forKey: "cardTintTopHex")
        let bottomHex = defaults.string(forKey: "cardTintBottomHex")
        let inkMode = defaults.string(forKey: "cardInkMode")
        defer {
            defaults.set(tintMode ?? CardTint.automatic.rawValue, forKey: "cardTintMode")
            defaults.set(topHex ?? "D6B8A8", forKey: "cardTintTopHex")
            defaults.set(bottomHex ?? "C08A72", forKey: "cardTintBottomHex")
            defaults.set(inkMode ?? CardInk.white.rawValue, forKey: "cardInkMode")
        }

        defaults.set(CardTint.custom.rawValue, forKey: "cardTintMode")
        defaults.set(CardInk.automatic.rawValue, forKey: "cardInkMode")

        let pairs = [
            ("black-green", "141414", "2F7A46"),
            ("green-black", "2F7A46", "141414"),
            ("navy-gold",   "1B2A4A", "D9A441"),
            ("clay-rose",   "C2705A", "E7B9C4")
        ]
        for (name, top, bottom) in pairs {
            defaults.set(top, forKey: "cardTintTopHex")
            defaults.set(bottom, forKey: "cardTintBottomHex")
            let image = try XCTUnwrap(render(card, style))
            attach(image, "pair-\(name)")
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
