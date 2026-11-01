//
//  CardStyle.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

enum CardStyle: String, CaseIterable, Identifiable, Codable {
    case roseDusk, twilightBlush, blushStone, lavenderMist, sageReflection,
         goldenDawn, oceanCalm, forestDeep, sunsetCoral, midnightInk,
         peachCream, mintFresh, wisteria, desertSand, stormCloud,
         cherryBlossom, amberEmber, arcticSky, oliveGrove, plumNight,
         terracotta, tealLagoon, honeyLinen, slateBlue

    var id: String { rawValue }

    // MARK: - Palette
    // Top / Mid / Bottom — every gradient is a 3-stop vertical fade.
    private var top: Color    { Color(hex: topHex) }
    private var mid: Color    { Color(hex: midHex) }
    private var bottom: Color { Color(hex: bottomHex) }

    private var topHex: String {
        // Restored palette: 13 soft gradients across 24 card names.
        switch self {
        case .roseDusk:       return "C9C6D6"
        case .twilightBlush:  return "D8AB9A"
        case .blushStone:     return "E9D2C0"
        case .lavenderMist:   return "E9DAC1"
        case .sageReflection: return "93B7AB"
        case .goldenDawn:     return "2D3A5C"
        case .oceanCalm:      return "8FA9C4"
        case .forestDeep:     return "F0E5D2"
        case .sunsetCoral:    return "EACABC"
        case .midnightInk:    return "E8D5BA"
        case .peachCream:     return "A8C7BB"
        case .mintFresh:      return "B3A9D2"
        case .wisteria:       return "86A9B4"
        case .desertSand:     return "C9C6D6"
        case .stormCloud:     return "D8AB9A"
        case .cherryBlossom:  return "E9D2C0"
        case .amberEmber:     return "E9DAC1"
        case .arcticSky:      return "93B7AB"
        case .oliveGrove:     return "2D3A5C"
        case .plumNight:      return "8FA9C4"
        case .terracotta:     return "F0E5D2"
        case .tealLagoon:     return "EACABC"
        case .honeyLinen:     return "E8D5BA"
        case .slateBlue:      return "A8C7BB"
        }
    }

    private var midHex: String {
        // Four families were too pale, so their stops were deepened ~10%;
        // the clay/rose, blush, coral and lilac-oat groups now read as cards
        // instead of blending into the paper page behind them.
        switch self {
        case .roseDusk:       return "D6B8A8"
        case .twilightBlush:  return "E7CCB7"
        case .blushStone:     return "F2DCC8"
        case .lavenderMist:   return "B69876"
        case .sageReflection: return "D5DCC5"
        case .goldenDawn:     return "4A4763"
        case .oceanCalm:      return "A8C5D9"
        case .forestDeep:     return "BFBDB6"
        case .sunsetCoral:    return "EDD2C4"
        case .midnightInk:    return "D2C6D6"
        case .peachCream:     return "C8D5C9"
        case .mintFresh:      return "B5B0D0"
        case .wisteria:       return "8AAEB8"
        case .desertSand:     return "D6B8A8"
        case .stormCloud:     return "E7CCB7"
        case .cherryBlossom:  return "F2DCC8"
        case .amberEmber:     return "B69876"
        case .arcticSky:      return "D5DCC5"
        case .oliveGrove:     return "4A4763"
        case .plumNight:      return "A8C5D9"
        case .terracotta:     return "BFBDB6"
        case .tealLagoon:     return "EDD2C4"
        case .honeyLinen:     return "D2C6D6"
        case .slateBlue:      return "C8D5C9"
        }
    }

    private var bottomHex: String {
        // Bottom stop — kept light enough for the espresso ink.
        switch self {
        case .roseDusk:       return "E8DCCC"
        case .twilightBlush:  return "EFDAC6"
        case .blushStone:     return "DDB59A"
        case .lavenderMist:   return "F4ECD8"
        case .sageReflection: return "F2EAD6"
        case .goldenDawn:     return "3B3550"
        case .oceanCalm:      return "D6D8DC"
        case .forestDeep:     return "B4AFA2"
        case .sunsetCoral:    return "F2DFD2"
        case .midnightInk:    return "DED5C2"
        case .peachCream:     return "E8E0CE"
        case .mintFresh:      return "E8E0D0"
        case .wisteria:       return "E0DDD0"
        case .desertSand:     return "E8DCCC"
        case .stormCloud:     return "EFDAC6"
        case .cherryBlossom:  return "DDB59A"
        case .amberEmber:     return "F4ECD8"
        case .arcticSky:      return "F2EAD6"
        case .oliveGrove:     return "3B3550"
        case .plumNight:      return "D6D8DC"
        case .terracotta:     return "B4AFA2"
        case .tealLagoon:     return "F2DFD2"
        case .honeyLinen:     return "DED5C2"
        case .slateBlue:      return "E8E0CE"
        }
    }

    var palette: [Color] { [top, mid, bottom] }

    /// The card background: a vertical (top → bottom) `LinearGradient`
    /// ready to drop into a `.fill(...)` modifier on any RoundedRectangle.
    func cardBackground() -> LinearGradient {
        LinearGradient(
            colors: palette,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Ink
    //
    // Thirteen soft gradients across twenty-four cards; the dusk pair is the
    // only deep one, so white ink applies there and the espresso ink elsewhere. Text used to be hard-coded white, which
    // measured 1.1–2.4:1 on the pastel cards — far below the 4.5:1 body-text
    // minimum. Ink now follows the gradient: deep espresso on paper, white on
    // dusk, all taken from the design system's existing ink tokens.

    /// True for the gradients that stay dark edge to edge.
    var hasDeepTone: Bool {
        self == .goldenDawn || self == .oliveGrove
    }

    /// Body ink — the verse and the reflection paragraphs.
    var ink: Color {
        hasDeepTone ? .white : Design.paperInkDeep
    }

    /// Secondary ink — reference line, section labels.
    var inkSecondary: Color {
        hasDeepTone ? Color.white.opacity(0.88) : Design.paperInk
    }

    /// Quiet ink — the small caption and the "tap to return" hint. Kept above
    /// 4.5:1 rather than fading to invisibility.
    var inkTertiary: Color {
        hasDeepTone ? Color.white.opacity(0.62) : Design.paperInk.opacity(0.78)
    }

    /// Fill behind the round ? / ✓ chips.
    var inkChipFill: Color {
        hasDeepTone ? Color.white.opacity(0.18) : Design.paperInkDeep.opacity(0.10)
    }

    // MARK: - Date-based picker
    /// Same date → same style. This guarantees the home card never "jumps"
    /// to a different colour mid-day, while consecutive days rotate through
    /// the full 24-style palette.
    static func forDate(_ date: Date) -> CardStyle {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        // yyyymmdd as a stable integer seed.
        let seed = (comps.year ?? 1970) * 10000 + (comps.month ?? 1) * 100 + (comps.day ?? 1)
        let all = CardStyle.allCases
        let idx = abs(seed) % all.count
        return all[idx]
    }

    /// Stable picker for a card id (used by share/export paths that don't
    /// have a calendar date handy).
    ///
    /// `String.hashValue` is seeded per process, so the old
    /// `abs(id.hashValue) % all.count` gave every card a different gradient on
    /// every launch. FNV-1a is deterministic across launches and OS versions.
    static func forCardId(_ id: String) -> CardStyle {
        let all = CardStyle.allCases
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return all[Int(hash % UInt64(all.count))]
    }
}
