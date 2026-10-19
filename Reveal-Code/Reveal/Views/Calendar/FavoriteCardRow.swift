//
//  FavoriteCardRow.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct FavoriteCardRow: View {
    let card: RevealCard
    let language: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.referenceText(language: language))
                .font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent)
            Text("\"\(card.verseText(language: language))\"")
                .font(.custom("Georgia", size: 14)).foregroundColor(Color(hex: "3A3A3A")).lineLimit(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "FAF7F2")).shadow(color: Design.cardShadowColor, radius: 8))
    }
}
