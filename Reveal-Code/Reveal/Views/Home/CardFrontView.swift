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

    /// Localised scripture reference, e.g. "Mark 12:13" /
    /// "马可福音 12:13". Driven by the actual card data
    /// (`card.book`, `card.chapter`, `card.verse`), so every
    /// different card shows its own reference — never a
    /// fixed string.
    private var referenceLine: String {
        card.referenceText(language: language)
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
        ZStack {
            // ── Card base: rounded rectangle filled with the day's
            //    gradient (top → bottom, 3 stops). Text on top is white.
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(style.cardBackground())
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
                Text(language == "zh-Hans" ? "今日经文" : "Today's Verse")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white.opacity(0.75))
                    .tracking(1.5)
                    .textCase(.uppercase)

                Spacer(minLength: 24)

                // (b) The verse itself — serif, *light* weight (per
                // user request: not bold, not heavy), generous line
                // spacing, wrapped in curly quotes to keep the
                // scripture-card feel the rest of the app uses.
                Text(quotedVerse(card.verseText(language: language)))
                    .font(.custom("Georgia", size: 17))
                    .fontWeight(.light)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)
                    .padding(.horizontal, 28)

                // (c) Scripture reference (Book Chapter:Verse) —
                // serif, bold, slightly translucent so it reads as
                // a secondary line, pushed near the bottom of the
                // card.
                Text(referenceLine)
                    .font(.custom("Georgia-Bold", size: 13))
                    .bold()
                    .foregroundColor(.white.opacity(0.85))

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)

            // Favorite ⭐ — same top-right position as before so it
            // doesn't "jump" if the card flips. The button widget
            // itself is unchanged.
            .overlay(alignment: .topTrailing) {
                FavoriteButton(isFavorite: isFavorite, onTap: onFavorite)
                    .padding(14)
            }
        }
    }
}
