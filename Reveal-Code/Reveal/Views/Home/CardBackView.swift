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
    /// Same idea for the "Tap to return" hint — it's an instruction to the
    /// person holding the phone, not part of the artwork.
    var showsReturnHint: Bool = true

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
                .fill(style.cardBackground())
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 22) {
                // ── Heading: single word "Reflection" / "默想".
                Text(mainHeading)
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 26)
                    .padding(.top, 28)

                Spacer(minLength: 8)

                // ── Reflect section — circular ? icon + bold label
                //    + body paragraph from card.reflect.
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 34, height: 34)
                        Image(systemName: "questionmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reflectLabel)
                            .font(.custom("Georgia", size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(card.questionText(language: language))
                            .font(.custom("Georgia", size: 15))
                            .foregroundColor(.white.opacity(0.92))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 26)

                Spacer(minLength: 2)

                // ── Action section — circular ✓ icon + bold label
                //    + body paragraph from card.action.
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 34, height: 34)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(actionLabel)
                            .font(.custom("Georgia", size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(card.actionText(language: language))
                            .font(.custom("Georgia", size: 15))
                            .foregroundColor(.white.opacity(0.92))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 26)

                Spacer(minLength: 0)

                // ── Bottom: "Tap to return" hint, centred.
                if showsReturnHint {
                    Text(tapToReturn)
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(.white.opacity(0.55))
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
        }
    }
}
