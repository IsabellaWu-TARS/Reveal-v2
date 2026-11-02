//
//  CardTint.swift
//  Reveal
//
//  User-chosen card colour.
//
//  The daily palette still owns the look by default — each date keeps its own
//  gradient. This lets a person override it with a colour of their own, or go
//  back to the daily palette at any time.
//
//  Whatever they pick, the card stays a three-stop vertical fade in the same
//  shape as the built-in gradients, so a custom card still looks like a Reveal
//  card rather than a flat block.
//

import SwiftUI
import UIKit

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

    init(style: CardStyle, mode: CardTint, customHex: String) {
        switch mode {
        case .automatic:
            stops = style.palette
            isDeep = style.hasDeepTone
        case .custom:
            let base = CardTintPalette.hsb(from: customHex)
            // Same shape as the built-in gradients: a lighter top, the chosen
            // colour in the middle, a slightly deeper bottom.
            let top = CardTintPalette.color(h: base.h, s: base.s * 0.92, b: min(1, base.b + 0.10))
            let mid = CardTintPalette.color(h: base.h, s: base.s, b: base.b)
            let bottom = CardTintPalette.color(h: base.h, s: min(1, base.s * 1.05), b: max(0, base.b - 0.12))
            stops = [top, mid, bottom]
            // 0.21 is the crossover where white and espresso ink give the same
            // contrast, so Automatic always lands on the more readable of the
            // two rather than falling into a muddy middle.
            isDeep = CardTintPalette.luminance(hex: customHex) < 0.21
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: stops, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Colour maths

    static func color(h: CGFloat, s: CGFloat, b: CGFloat) -> Color {
        Color(UIColor(hue: h, saturation: s, brightness: b, alpha: 1))
    }

    static func hsb(from hex: String) -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        var r: CGFloat = 1, g: CGFloat = 1, bl: CGFloat = 1, a: CGFloat = 1
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        if scanner.scanHexInt64(&value), cleaned.count == 6 {
            r = CGFloat((value >> 16) & 0xFF) / 255
            g = CGFloat((value >> 8) & 0xFF) / 255
            bl = CGFloat(value & 0xFF) / 255
        }
        _ = a
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0
        UIColor(red: r, green: g, blue: bl, alpha: 1).getHue(&h, saturation: &s, brightness: &br, alpha: nil)
        return (h, s, br)
    }

    /// WCAG relative luminance, used only to pick ink and never shown as a number.
    static func luminance(hex: String) -> Double {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        guard scanner.scanHexInt64(&value), cleaned.count == 6 else { return 1 }
        func channel(_ c: UInt64) -> Double {
            let v = Double(c) / 255
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let r = channel((value >> 16) & 0xFF)
        let g = channel((value >> 8) & 0xFF)
        let b = channel(value & 0xFF)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
