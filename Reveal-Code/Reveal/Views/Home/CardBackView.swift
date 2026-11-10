//
//  CardBackView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct CardBackView: View {
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
    /// Same idea for the "Tap to return" hint — it's an instruction to the
    /// person holding the phone, not part of the artwork.
    var showsReturnHint: Bool = true

    @AppStorage("cardTintMode") private var tintModeRaw: String = CardTint.automatic.rawValue
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

    /// Main heading on the back of the card. Per the new card-back
    /// layout reference the heading is a single word — "Reflection"
    /// (zh: "默想") — not the old two-word "Reflect & Action".
    private var mainHeading: String {
        language == "zh-Hans" ? "默想" : "Reflection"
    }
    private var reflectLabel: String { language == "zh-Hans" ? "反思" : "Reflect" }
    private var actionLabel:  String { language == "zh-Hans" ? "行动" : "Action" }
    private var tapToReturn:   String { language == "zh-Hans" ? "点击返回" : "Tap to return" }

    var body: some View {
        ZStack {
            // ── Card base: same daily gradient as the front.
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(tintPalette.gradient)
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 22) {
                // ── Heading: single word "Reflection" / "默想".
                Text(mainHeading)
                    .font(.custom("Georgia", size: 25))
                    .fontWeight(.bold)
                    .foregroundColor(inkPalette.body)
                    .padding(.horizontal, 26)
                    .padding(.top, 28)

                Spacer(minLength: 8)

                // ── Reflect section — circular ? icon + bold label
                //    + body paragraph from card.reflect.
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(inkPalette.chipFill)
                            .frame(width: 34, height: 34)
                        Image(systemName: "questionmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(inkPalette.body)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reflectLabel)
                            .font(.custom("Georgia", size: 15))
                            .fontWeight(.bold)
                            .foregroundColor(inkPalette.body)
                        Text(card.questionText(language: language))
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(inkPalette.body)
                            .lineSpacing(5)
                            .minimumScaleFactor(0.7)
                            .lineLimit(8)
                    }
                }
                .padding(.horizontal, 26)

                Spacer(minLength: 2)

                // ── Action section — circular ✓ icon + bold label
                //    + body paragraph from card.action.
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(inkPalette.chipFill)
                            .frame(width: 34, height: 34)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(inkPalette.body)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(actionLabel)
                            .font(.custom("Georgia", size: 15))
                            .fontWeight(.bold)
                            .foregroundColor(inkPalette.body)
                        Text(card.actionText(language: language))
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(inkPalette.body)
                            .lineSpacing(5)
                            .minimumScaleFactor(0.7)
                            .lineLimit(6)
                    }
                }
                .padding(.horizontal, 26)

                Spacer(minLength: 0)

                // ── Bottom: "Tap to return" hint, centred.
                if showsReturnHint {
                    Text(tapToReturn)
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(inkPalette.tertiary)
                        .tracking(2)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 28)
                }
            }

            // Favorite ⭐ — same position as front, so it doesn't
            // visually move during the flip.
            .overlay(alignment: .topTrailing) {
                if showsFavoriteButton {
                    FavoriteButton(isFavorite: isFavorite, onTap: onFavorite)
                        .padding(14)
                }
            }
            .clipped()
        }
        // Same ceiling as the front face: a card that must not change size.
        .dynamicTypeSize(.xSmall ... .xxLarge)
    }
}
