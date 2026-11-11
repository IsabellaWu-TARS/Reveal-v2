//
//  CardTypeScale.swift
//  Reveal
//
//  One type scale for both faces of the card.
//
//  The card is a fixed surface, but the person reading it may have their
//  system text set to anything. Both faces now derive every size from the
//  card's own width, and both grow with Dynamic Type up to the same ceiling
//  (`.xLarge`) — so the front and the back stay in proportion instead of one
//  face inflating while the other stays frozen.
//

import SwiftUI

struct CardTypeScale {
    let width: CGFloat

    private func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        min(max(value, low), high)
    }

    // MARK: - Front

    var verse: CGFloat      { clamp(width * 0.046 + 1, 13, 23) }
    var caption: CGFloat    { clamp(width * 0.028 + 1, 10, 13) }
    var reference: CGFloat  { clamp(width * 0.033 + 1, 11.5, 15) }
    var horizontal: CGFloat { clamp(width * 0.072, 16, 30) }
    var vertical: CGFloat   { clamp(width * 0.072, 16, 30) }

    // MARK: - Back

    var title: CGFloat      { clamp(width * 0.0615 + 1, 20, 30) }
    var label: CGFloat      { clamp(width * 0.0359 + 1, 13, 18) }
    var body: CGFloat       { clamp(width * 0.0385 + 1, 14, 20) }
    var hint: CGFloat       { clamp(width * 0.0308 + 1, 11, 15) }

    /// Ceiling for Dynamic Type on a card. Past this the surface would have to
    /// give, so the type stops growing and long passages shrink instead.
    static let dynamicTypeRange: ClosedRange<DynamicTypeSize> = .xSmall ... .xLarge
}
