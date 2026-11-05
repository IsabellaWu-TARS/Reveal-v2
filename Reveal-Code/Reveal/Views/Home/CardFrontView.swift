//
//  CardFrontView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct CardFrontView: View {
    let card: RevealCard
    let language: String
    let style: CardStyle
    let onFavorite: () -> Void
    let isFavorite: Bool
    /// Hidden when the card is rendered for sharing, so the exported PNG
    /// doesn't bake in the favourite star. Default keeps the live card as is.
    var showsFavoriteButton: Bool = true
    /// Past days keep the palette they were shown with; only today's card
    /// follows the person's chosen colours.
    var usesUserTint: Bool = true

    /// Override for the small line above the verse. The calendar shows past
    /// days, where "Today's Verse" would be wrong. Defaults to nil so the
    /// home card is untouched.
    var headline: String? = nil

    @AppStorage("cardTintMode") private var tintModeRaw: String = CardTint.automatic.rawValue
    @AppStorage(ScriptPreference.key) private var scriptRaw: String = ChineseScript.simplified.rawValue
    @AppStorage("cardTintTopHex") private var tintTopHex: String = "D6B8A8"
    @AppStorage("cardTintBottomHex") private var tintBottomHex: String = "C08A72"

    /// Background for this face: the day's gradient or the person's own colour.
    private var tintPalette: CardTintPalette {
        CardTintPalette(
            style: style,
            mode: usesUserTint ? (CardTint(rawValue: tintModeRaw) ?? .automatic) : .automatic,
            topHex: tintTopHex,
            bottomHex: tintBottomHex
        )
    }

    @AppStorage("cardInkMode") private var inkModeRaw: String = CardInk.white.rawValue
    @AppStorage("cardInkCustomHex") private var inkCustomHex: String = "FFFFFF"

    /// Ink for this face: the per-card default, or whatever the person chose
    /// in Settings → Card Text Colour.
    private var inkPalette: CardInkPalette {
        CardInkPalette(
            isDeep: tintPalette.isDeep,
            mode: CardInk(rawValue: inkModeRaw) ?? .automatic,
            customHex: inkCustomHex
        )
    }

    /// Localised scripture reference, e.g. "Mark 12:13" /
    /// "马可福音 12:13". Driven by the actual card data
    /// (`card.book`, `card.chapter`, `card.verse`), so every
    /// different card shows its own reference — never a
    /// fixed string.
    private var referenceLine: String {
        card.referenceText(language: language)
    }

    /// Type sizes derived from the card's own width.
    ///
    /// They used to be fixed points, which broke on a phone with Display Zoom
    /// on: the screen reports ~320pt instead of 390, the card shrinks with it,
    /// and 17pt verse text then fills — and overflows — a much smaller card.
    /// Long English verses suffer first; Chinese is dense enough to hide it.
    struct TypeScale {
        let width: CGFloat

        private func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
            min(max(value, low), high)
        }

        var verse: CGFloat      { clamp(width * 0.046, 12, 22) }
        var caption: CGFloat    { clamp(width * 0.028, 9, 12) }
        var reference: CGFloat  { clamp(width * 0.033, 10.5, 14) }
        var horizontal: CGFloat { clamp(width * 0.072, 16, 30) }
        var vertical: CGFloat   { clamp(width * 0.072, 16, 30) }
    }

    /// Verse text wrapped in typographic quotes for the card face.
    /// Some translations already open with a quote (direct speech, e.g.
    /// Leviticus 23:22 in WEB), which used to render as ““…””.
    private func quotedVerse(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let openers: Set<Character> = ["“", "‘", "\"", "'"]
        if let first = trimmed.first, openers.contains(first) { return trimmed }
        return "“\(trimmed)”"
    }

    var body: some View {
        GeometryReader { geo in
        let scale = TypeScale(width: geo.size.width)
        ZStack {
            // ── Card base: rounded rectangle filled with the day's
            //    gradient (top → bottom, 3 stops). Text ink follows the
            //    gradient (see CardStyle.ink) so it stays readable.
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(tintPalette.gradient)
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)

            // ── Layout: a small "Today's Verse" caption sits at the top
            //    of the card (light weight, low opacity), while the
            //    verse and the book·chapter line are pushed to the
            //    bottom and rendered bold. Padding around the edges
            //    is kept close to the original card weight.
            VStack(spacing: 14) {
                // (a) Top caption — tiny serif, light weight, low
                // opacity so it reads as a quiet label rather than
                // competing with the verse.
                Text(headline ?? (language == "zh-Hans" ? "今日经文" : "Today's Verse"))
                    .font(.system(size: scale.caption, weight: .light))
                    .foregroundColor(inkPalette.tertiary)
                    .tracking(1.5)
                    .textCase(.uppercase)

                Spacer(minLength: 24)

                // (b) The verse itself — serif, *light* weight (per
                // user request: not bold, not heavy), generous line
                // spacing, wrapped in curly quotes to keep the
                // scripture-card feel the rest of the app uses.
                Text(quotedVerse(card.verseText(language: language)))
                    .font(.custom("Georgia", size: scale.verse))
                    .fontWeight(.light)
                    .foregroundColor(inkPalette.body)
                    .multilineTextAlignment(.center)
                    .lineSpacing(scale.verse * 0.41)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, scale.horizontal)

                // (c) Scripture reference (Book Chapter:Verse) —
                // serif, bold, slightly translucent so it reads as
                // a secondary line, pushed near the bottom of the
                // card.
                Text(referenceLine)
                    .font(.custom("Georgia-Bold", size: scale.reference))
                    .bold()
                    .foregroundColor(inkPalette.secondary)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, scale.horizontal)
            .padding(.vertical, scale.vertical)

            // Favorite ⭐ — same top-right position as before so it
            // doesn't "jump" if the card flips. The button widget
            // itself is unchanged.
            .overlay(alignment: .topTrailing) {
                if showsFavoriteButton {
                    FavoriteButton(isFavorite: isFavorite, onTap: onFavorite)
                        .padding(14)
                }
            }
        }
        }
        // The card is a fixed-size artefact; let its type track the card, not
        // the system text size, or the verse overflows on larger settings.
        .dynamicTypeSize(.xSmall ... .large)
    }
}
