//
//  CardInk.swift
//  Reveal
//
//  User-chosen ink for the daily card.
//
//  Default is white, as requested for the shipped look. Automatic ink (deep
//  espresso on the pale gradients) is one tap away in Settings and is the only
//  mode that clears 4.5:1 on every card — white on the palest cards measures
//  about 1.2:1, so that choice is genuinely hard to read.
//
//  The system picker is the Apple-recommended control here (SwiftUI
//  `ColorPicker`), so there is no custom colour wheel to get wrong, and it
//  already supports VoiceOver, Dynamic Type and the accessibility inspector.
//

import SwiftUI
import UIKit

enum CardInk: String, CaseIterable, Identifiable {
    case automatic
    case white
    case ink
    case custom

    var id: String { rawValue }

    func title(language: String) -> String {
        let zh = language == "zh-Hans"
        switch self {
        case .automatic: return zh ? "自动（随卡片）" : "Automatic"
        case .white:     return zh ? "白色" : "White"
        case .ink:       return zh ? "墨色" : "Ink"
        case .custom:    return zh ? "自定义…" : "Custom…"
        }
    }
}

/// Resolved ink for one card face.
struct CardInkPalette {
    let body: Color
    let secondary: Color
    let tertiary: Color
    let chipFill: Color

    init(style: CardStyle, mode: CardInk, customHex: String) {
        switch mode {
        case .automatic:
            body = style.ink
            secondary = style.inkSecondary
            tertiary = style.inkTertiary
            chipFill = style.inkChipFill
        case .white:
            body = .white
            secondary = .white.opacity(0.88)
            tertiary = .white.opacity(0.70)
            chipFill = Color.white.opacity(0.18)
        case .ink:
            body = Design.paperInkDeep
            secondary = Design.paperInk
            tertiary = Design.paperInk.opacity(0.78)
            chipFill = Design.paperInkDeep.opacity(0.10)
        case .custom:
            let chosen = Color(hex: customHex)
            body = chosen
            secondary = chosen.opacity(0.88)
            tertiary = chosen.opacity(0.78)
            chipFill = chosen.opacity(0.12)
        }
    }
}

// MARK: - Colour ⇄ hex

extension Color {
    /// `#RRGGBB` for storage. Returns white if the colour cannot be resolved
    /// (e.g. a pattern colour), so a bad value never breaks the card.
    var hexString: String {
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return "FFFFFF" }
        func clamp(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "%02X%02X%02X", clamp(r), clamp(g), clamp(b))
    }
}
