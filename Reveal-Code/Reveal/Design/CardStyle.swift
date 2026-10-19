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
        // P16 (per user request): card palette has been completely
        // refreshed from the new colour reference image. All 24
        // `CardStyle` cases now point at the 13 new palette swatches
        // (cycling 1→13, then 1→11 again for the remaining cases) so
        // the existing `forCardId(_:)` / `forDate(_:)` random
        // selection logic continues to work without any other
        // changes. Case names are kept (Codable stability); only the
        // hex values change.
        switch self {
        case .roseDusk:        return "D4D2DE"  // swatch 1 — light grey-violet
        case .twilightBlush:   return "E0B7A8"  // swatch 2 — peach
        case .blushStone:      return "E9D2C0"  // swatch 3 — warm cream
        case .lavenderMist:    return "E9DAC1"  // swatch 4 — amber
        case .sageReflection:  return "93B7AB"  // swatch 5 — sage cream
        case .goldenDawn:      return "2D3A5C"  // swatch 6 — twilight dusk
        case .oceanCalm:       return "3A4E6B"  // swatch 7 — blue sky
        case .forestDeep:      return "F0E5D2"  // swatch 8 — oat / linen
        case .sunsetCoral:     return "F2DDD5"  // swatch 9 — pink mist
        case .midnightInk:     return "F0E5D2"  // swatch 10 — lilac oat
        case .peachCream:      return "A8C7BB"  // swatch 11 — teal mist
        case .mintFresh:       return "4E4870"  // swatch 12 — lavender dusk
        case .wisteria:        return "2E4F5C"  // swatch 13 — deep teal
        // Cycle back through swatches 1–11 for the remaining cases
        // so the full 24-style palette stays balanced.
        case .desertSand:      return "D4D2DE"  // swatch 1
        case .stormCloud:      return "E0B7A8"  // swatch 2
        case .cherryBlossom:   return "E9D2C0"  // swatch 3
        case .amberEmber:      return "E9DAC1"  // swatch 4
        case .arcticSky:       return "93B7AB"  // swatch 5
        case .oliveGrove:      return "2D3A5C"  // swatch 6
        case .plumNight:       return "3A4E6B"  // swatch 7
        case .terracotta:      return "F0E5D2"  // swatch 8
        case .tealLagoon:      return "F2DDD5"  // swatch 9
        case .honeyLinen:      return "F0E5D2"  // swatch 10
        case .slateBlue:       return "A8C7BB"  // swatch 11
        }
    }

    private var midHex: String {
        switch self {
        case .roseDusk:        return "E1C4B4"  // swatch 1
        case .twilightBlush:   return "F1D8C5"  // swatch 2
        case .blushStone:      return "F2DCC8"  // swatch 3
        case .lavenderMist:    return "B69876"  // swatch 4
        case .sageReflection:  return "D5DCC5"  // swatch 5
        case .goldenDawn:      return "5C5A7A"  // swatch 6
        case .oceanCalm:       return "A8C5D9"  // swatch 7
        case .forestDeep:      return "BFBDB6"  // swatch 8
        case .sunsetCoral:     return "F4E5DA"  // swatch 9
        case .midnightInk:     return "DDD2DE"  // swatch 10
        case .peachCream:      return "C8D5C9"  // swatch 11
        case .mintFresh:       return "B5B0D0"  // swatch 12
        case .wisteria:        return "8AAEB8"  // swatch 13
        case .desertSand:      return "E1C4B4"  // swatch 1
        case .stormCloud:      return "F1D8C5"  // swatch 2
        case .cherryBlossom:   return "F2DCC8"  // swatch 3
        case .amberEmber:      return "B69876"  // swatch 4
        case .arcticSky:       return "D5DCC5"  // swatch 5
        case .oliveGrove:      return "5C5A7A"  // swatch 6
        case .plumNight:       return "A8C5D9"  // swatch 7
        case .terracotta:      return "BFBDB6"  // swatch 8
        case .tealLagoon:      return "F4E5DA"  // swatch 9
        case .honeyLinen:      return "DDD2DE"  // swatch 10
        case .slateBlue:       return "C8D5C9"  // swatch 11
        }
    }

    private var bottomHex: String {
        switch self {
        case .roseDusk:        return "F2EBE2"  // swatch 1
        case .twilightBlush:   return "F8E8D8"  // swatch 2
        case .blushStone:      return "DDB59A"  // swatch 3
        case .lavenderMist:    return "F4ECD8"  // swatch 4
        case .sageReflection:  return "F2EAD6"  // swatch 5
        case .goldenDawn:      return "DCD3BC"  // swatch 6
        case .oceanCalm:       return "D6D8DC"  // swatch 7
        case .forestDeep:      return "807F75"  // swatch 8
        case .sunsetCoral:     return "F8F1E6"  // swatch 9
        case .midnightInk:     return "E8E2D2"  // swatch 10
        case .peachCream:      return "E8E0CE"  // swatch 11
        case .mintFresh:       return "E8E0D0"  // swatch 12
        case .wisteria:        return "E0DDD0"  // swatch 13
        case .desertSand:      return "F2EBE2"  // swatch 1
        case .stormCloud:      return "F8E8D8"  // swatch 2
        case .cherryBlossom:   return "DDB59A"  // swatch 3
        case .amberEmber:      return "F4ECD8"  // swatch 4
        case .arcticSky:       return "F2EAD6"  // swatch 5
        case .oliveGrove:      return "DCD3BC"  // swatch 6
        case .plumNight:       return "D6D8DC"  // swatch 7
        case .terracotta:      return "807F75"  // swatch 8
        case .tealLagoon:      return "F8F1E6"  // swatch 9
        case .honeyLinen:      return "E8E2D2"  // swatch 10
        case .slateBlue:       return "E8E0CE"  // swatch 11
        }
    }

    // MARK: - Display

    /// Human-readable name (used by future Settings UI / card legend).
    var displayName: String {
        switch self {
        case .roseDusk:        return "Rose Dusk"
        case .twilightBlush:   return "Twilight Blush"
        case .blushStone:      return "Blush Stone"
        case .lavenderMist:    return "Lavender Mist"
        case .sageReflection:  return "Sage Reflection"
        case .goldenDawn:      return "Golden Dawn"
        case .oceanCalm:       return "Ocean Calm"
        case .forestDeep:      return "Forest Deep"
        case .sunsetCoral:     return "Sunset Coral"
        case .midnightInk:     return "Midnight Ink"
        case .peachCream:      return "Peach Cream"
        case .mintFresh:       return "Mint Fresh"
        case .wisteria:        return "Wisteria"
        case .desertSand:      return "Desert Sand"
        case .stormCloud:      return "Storm Cloud"
        case .cherryBlossom:   return "Cherry Blossom"
        case .amberEmber:      return "Amber Ember"
        case .arcticSky:       return "Arctic Sky"
        case .oliveGrove:      return "Olive Grove"
        case .plumNight:       return "Plum Night"
        case .terracotta:      return "Terracotta"
        case .tealLagoon:      return "Teal Lagoon"
        case .honeyLinen:      return "Honey Linen"
        case .slateBlue:       return "Slate Blue"
        }
    }

    /// The 3-stop palette as `[Color]`, ordered top → mid → bottom.
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
