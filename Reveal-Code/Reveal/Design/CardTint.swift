//
//  CardTint.swift
//  Reveal
//
//  User-chosen card colour.
//
//  Two colours in, one Reveal gradient out. The person picks a top and a bottom
//  colour; those are blended into the same three-stop vertical fade the built-in
//  cards use, so a custom card still looks like a Reveal card rather than a raw
//  two-tone block.
//
//  Three rules keep the result readable whatever is chosen (black→green,
//  white→black, anything):
//    1. If the two colours are far apart in luminance the pair is compressed
//       toward its mean, so the card cannot span the unreadable middle.
//    2. Ink is whichever of white / espresso gives the better worst-case
//       contrast across all three stops — never a guess from one stop.
//    3. Any stop still short of 4.6:1 is nudged in brightness toward the ink.
//
//  Left on "Daily default", the card keeps rotating through the built-in
//  palette — a different gradient every date, exactly as before.
//

import SwiftUI

enum CardTint: String, CaseIterable, Identifiable {
    case automatic
    case custom

    var id: String { rawValue }

    func title(language: String) -> String {
        let zh = language == "zh-Hans"
        switch self {
        case .automatic: return zh ? "每日默认" : "Daily default"
        case .custom:    return zh ? "自定义…" : "Custom…"
        }
    }
}

/// Resolved card background for one face.
struct CardTintPalette {
    let stops: [Color]
    /// True when the card is dark enough that white ink is the readable choice.
    let isDeep: Bool

    /// - Parameters:
    ///   - topHex:    the person's upper colour
    ///   - bottomHex: the person's lower colour
    init(style: CardStyle, mode: CardTint, topHex: String, bottomHex: String) {
        switch mode {
        case .automatic:
            stops = style.palette
            isDeep = style.hasDeepTone

        case .custom:
            var top = RGB(hex: topHex)
            var bottom = RGB(hex: bottomHex)

            // 1. Compress a wide span so one ink can serve the whole face.
            if abs(top.luminance - bottom.luminance) > 0.35 {
                let mean = RGB.blend(top, bottom, 0.5)
                top = RGB.blend(top, mean, 0.55)
                bottom = RGB.blend(bottom, mean, 0.55)
            }

            let middle = RGB.blend(top, bottom, 0.5)

            var stopsHSB = [
                top.hsb.adjust(brightness: 0.08, saturationScale: 0.92),
                middle.hsb,
                bottom.hsb.adjust(brightness: -0.09, saturationScale: 1.03)
            ]

            // 2. Ink with the better worst-case contrast.
            let whiteWorst = stopsHSB.map { Self.contrast(HSB.white, $0) }.min() ?? 0
            let inkWorst = stopsHSB.map { Self.contrast(HSB.ink, $0) }.min() ?? 0
            let useWhite = whiteWorst >= inkWorst
            let ink = useWhite ? HSB.white : HSB.ink

            // 3. Nudge any stop that is still short of 4.6:1.
            let step: CGFloat = useWhite ? -0.04 : 0.04
            for i in stopsHSB.indices {
                var hs = stopsHSB[i]
                var guardCount = 0
                while Self.contrast(ink, hs) < 4.6 && guardCount < 24 {
                    hs = HSB(h: hs.h, s: hs.s, b: min(0.99, max(0.02, hs.b + step)))
                    guardCount += 1
                }
                stopsHSB[i] = hs
            }

            stops = stopsHSB.map { $0.color }
            isDeep = useWhite
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
    }

    /// One-time carry-over from the single-colour version of this setting.
    static func migrateLegacyTint() {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: "cardTintTopHex") == nil else { return }
        if let legacy = defaults.string(forKey: "cardTintCustomHex") {
            defaults.set(legacy, forKey: "cardTintTopHex")
            defaults.set(legacy, forKey: "cardTintBottomHex")
        }
    }

    // MARK: - Colour maths

    /// WCAG contrast between two HSB colours.
    static func contrast(_ a: HSB, _ b: HSB) -> Double {
        let la = a.luminance, lb = b.luminance
        let hi = max(la, lb), lo = min(la, lb)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// Luminance from a hex string — used by tests.
    static func luminance(hex: String) -> Double {
        RGB(hex: hex).luminance
    }
}

// MARK: - Small colour primitives

struct HSB {
    var h: CGFloat
    var s: CGFloat
    var b: CGFloat

    static let white = HSB(h: 0, s: 0, b: 1)
    /// The app's espresso ink, #2B1F12.
    static let ink = HSB(h: 0.08, s: 0.50, b: 0.17)

    func adjust(brightness delta: CGFloat, saturationScale: CGFloat) -> HSB {
        HSB(h: h,
            s: min(1, max(0, s * saturationScale)),
            b: min(1, max(0, b + delta)))
    }

    var color: Color {
        let c = rgb
        return Color(red: Double(c.r), green: Double(c.g), blue: Double(c.b))
    }

    var rgb: (r: CGFloat, g: CGFloat, b: CGFloat) {
        let i = Int(h * 6)
        let f = h * 6 - CGFloat(i)
        let p = b * (1 - s)
        let q = b * (1 - f * s)
        let t = b * (1 - (1 - f) * s)
        switch i % 6 {
        case 0: return (b, t, p)
        case 1: return (q, b, p)
        case 2: return (p, b, t)
        case 3: return (p, q, b)
        case 4: return (t, p, b)
        default: return (b, p, q)
        }
    }

    var luminance: Double {
        func channel(_ v: CGFloat) -> Double {
            let d = Double(v)
            return d <= 0.04045 ? d / 12.92 : pow((d + 0.055) / 1.055, 2.4)
        }
        let c = rgb
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
    }
}

struct RGB {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat

    init(hex: String) {
        var value: UInt64 = 0
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: cleaned)
        if scanner.scanHexInt64(&value), cleaned.count == 6 {
            r = CGFloat((value >> 16) & 0xFF) / 255
            g = CGFloat((value >> 8) & 0xFF) / 255
            b = CGFloat(value & 0xFF) / 255
        } else {
            r = 1; g = 1; b = 1
        }
    }

    init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.r = r; self.g = g; self.b = b
    }

    var hsb: HSB {
        let maxC = max(r, g, b), minC = min(r, g, b)
        let delta = maxC - minC
        var h: CGFloat = 0
        if delta > 0 {
            if maxC == r { h = ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
            else if maxC == g { h = (b - r) / delta + 2 }
            else { h = (r - g) / delta + 4 }
            h /= 6
            if h < 0 { h += 1 }
        }
        return HSB(h: h, s: maxC == 0 ? 0 : delta / maxC, b: maxC)
    }

    var luminance: Double {
        func channel(_ v: CGFloat) -> Double {
            let d = Double(v)
            return d <= 0.04045 ? d / 12.92 : pow((d + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    /// Linear blend on RGB — used for compressing the pair and for the middle stop.
    static func blend(_ a: RGB, _ b: RGB, _ t: CGFloat) -> RGB {
        RGB(r: a.r + (b.r - a.r) * t,
            g: a.g + (b.g - a.g) * t,
            b: a.b + (b.b - a.b) * t)
    }
}
