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

    /// The person's own size adjustment, set in Settings → Card Text Size.
    /// 1.0 leaves the card exactly as designed.
    var scale: CGFloat = 1.0

    /// Where the setting lives, and the range it can take.
    static let defaultScale: Double = 1.0
    static let scaleRange: ClosedRange<Double> = 0.88 ... 1.24

    private func clamp(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        min(max(value, low), high)
    }

    // MARK: - Front

    var verse: CGFloat      { clamp(width * 0.046 + 1, 13, 23) * scale }
    var caption: CGFloat    { clamp(width * 0.028 + 1, 10, 13) * scale }
    var reference: CGFloat  { clamp(width * 0.033 + 1, 11.5, 15) * scale }
    var horizontal: CGFloat { clamp(width * 0.072, 16, 30) }
    var vertical: CGFloat   { clamp(width * 0.072, 16, 30) }

    // MARK: - Back

    var title: CGFloat      { clamp(width * 0.0615 + 1, 20, 30) * scale }
    var label: CGFloat      { clamp(width * 0.0359 + 1, 13, 18) * scale }
    var body: CGFloat       { clamp(width * 0.0385 + 1, 14, 20) * scale }
    var hint: CGFloat       { clamp(width * 0.0308 + 1, 11, 15) * scale }

    /// Ceiling for Dynamic Type on a card. Past this the surface would have to
    /// give, so the type stops growing and long passages shrink instead.
    static let dynamicTypeRange: ClosedRange<DynamicTypeSize> = .xSmall ... .xLarge
}

/// The four sizes offered in Settings → Card Text Size.
///
/// A card is a fixed surface, so this scales the type inside it rather than the
/// card itself. Stored as a number so a partial step (or a future fifth size)
/// needs no migration.
enum CardTextSize: Double, CaseIterable, Identifiable {
    case small = 0.92
    case standard = 1.0
    case large = 1.10
    case extraLarge = 1.22

    var id: Double { rawValue }

    func title(language: String) -> String {
        let zh = language == "zh-Hans"
        switch self {
        case .small:      return zh ? "小" : "Small"
        case .standard:   return zh ? "标准" : "Default"
        case .large:      return zh ? "大" : "Large"
        case .extraLarge: return zh ? "特大" : "Larger"
        }
    }
}
