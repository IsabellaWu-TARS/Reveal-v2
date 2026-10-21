//
//  Design.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

enum HapticManager {
    static func light() { let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred() }
    static func medium() { let g = UIImpactFeedbackGenerator(style: .medium); g.impactOccurred() }
    static func soft() { let g = UIImpactFeedbackGenerator(style: .soft); g.impactOccurred() }
    static func success() { let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success) }
}

struct Design {
    static let accent = Color(hex: "A2A569")
    static let lightBackground = Color(hex: "FFFAE3")
    static let lightSurface = Color(hex: "FFF7D6")
    static let cardShadowColor = Color.black.opacity(0.08)
    static let cardRadius: CGFloat = 32
    static let notesRadius: CGFloat = 28
    static let springAnim = Animation.spring(response: 0.45, dampingFraction: 0.85)

    // ── P8: Paper-cream palette for the new scripture-style redesign ────────
    // The old palette used stark white ("FFFFFF") for text on a cream
    // background, which felt "tech" rather than "paper". We move everything
    // onto warm off-white tones so the reading experience feels like an
    // actual page from a Bible.
    /// Page background — warm cream paper (slightly darker than the card).
    static let paperBackground  = Color(hex: "F5EDDC")
    /// Card surface — lighter cream than the page, so the card pops.
    static let paperCardSurface = Color(hex: "FAF3E4")
    /// Primary text on the card — warm cream / parchment colour, **not**
    /// pure white. Closer to a slightly aged-paper tone.
    static let paperInk         = Color(hex: "3D2E1F")
    /// Deeper version of paperInk for emphasis (e.g. verse text body).
    static let paperInkDeep     = Color(hex: "2B1F12")
    /// Soft secondary text — faded brown-cream.
    static let paperInkMuted    = Color(hex: "7A6852")
    /// Hint / tertiary text — very faded.
    static let paperInkHint     = Color(hex: "A89880")
    /// Footer chip background — translucent cream that mimics a wax seal.
    static let paperChipFill    = Color.white.opacity(0.55)

    // ── Button sizes ────────────────────────────────────────────────────────
    // These used to be hard-coded (44, 52, 40, …) so they looked right on one
    // phone and wrong on the others. They now scale off the window width.
    //
    // `UIScreen.main` was deprecated in iOS 26, and the old
    // `nonisolated(unsafe)` workaround around it is no longer needed either:
    // CGFloat/Bool are Sendable, so a plain `static let` is already safe and
    // the attribute only produced warnings. The width comes from the active
    // window scene, with the 402pt reference size as a fallback for the rare
    // case where no scene exists yet.
    private static let _screenWidth: CGFloat = {
        let sceneWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width
        return sceneWidth ?? 402
    }()
    /// Tiny iPhone class (SE / 13 mini / older 4.7"–5.4" devices).
    static let isCompactWidth: Bool = _screenWidth <= 390
    /// Large iPhone class (Plus / Max — 6.5"+).
    static let isLargeScreen: Bool = _screenWidth >= 430

    /// Standard 44pt tap-target for primary icon buttons (Home / Back / Share / Settings).
    static let iconButtonSize: CGFloat = isLargeScreen ? 52 : 44
    /// The label that lives under a bottom-bar icon — a bit smaller on compact screens.
    static let bottomBarLabelSize: CGFloat = isCompactWidth ? 9 : 10
    /// Capsule "Notes" button height.
    static let noteButtonHeight: CGFloat = isLargeScreen ? 56 : 52
    /// Default side margin used across screens so the layout is symmetric on
    /// every iPhone width.
    static let horizontalPadding: CGFloat = isLargeScreen ? 32 : 24
    /// Calendar "weekday letters" + grid spacing.
    static let calendarGridSpacing: CGFloat = isCompactWidth ? 4 : 6

    /// Unified corner-button size used by all 4 card corners, so the layout
    /// reads as a balanced frame.
    static let cornerButtonSize: CGFloat = isLargeScreen ? 48 : 44

    // Card gradient palettes
    static let pinkGradient    = [Color(hex: "E8A5A5"), Color(hex: "F5D4D4")]
    static let blueGradient   = [Color(hex: "B7E4F0"), Color(hex: "D8C8F4")]
    static let sageGradient   = [Color(hex: "C5D5A0"), Color(hex: "D8E8B5")]
    static let warmGradient   = [Color(hex: "F5D4A0"), Color(hex: "FAE8C8")]
    static let lavenderGradient = [Color(hex: "D8C8F4"), Color(hex: "E8D8F8")]
    static let mintGradient   = [Color(hex: "B7E4D4"), Color(hex: "D8F0E8")]
    static let peachGradient  = [Color(hex: "F5C4A0"), Color(hex: "FAE0C8")]

    static let allGradients: [[Color]] = [pinkGradient, blueGradient, sageGradient, warmGradient, lavenderGradient, mintGradient, peachGradient]

    static func gradientForDay(_ day: Int) -> [Color] {
        allGradients[day % allGradients.count]
    }

    // ── P11: Bold scripture-banner gradients ──────────────────────────────────
    // The 17:07 reference design uses a saturated dark gradient for the top
    // 40% of the card with white serif text on it. We keep 6 variants so
    // each card picks a different one based on its stable id (so the user
    // sees a real variety, not the same gradient every day).
    //
    // Each gradient is a 3-stop vertical gradient that fades from a deep
    // saturated tone at the top to a slightly lighter mid-tone at the
    // bottom — the cream paper card surface is rendered *below* this band.

    /// Deep crimson — first one we matched from the reference.
    static let bannerCrimson: [Color] = [
        Color(hex: "B33A3A"),  // top — saturated blood-red
        Color(hex: "8E2727"),  // mid — slightly darker
        Color(hex: "6B1B1B")   // bottom — deepest, anchors the band
    ]
    /// Royal indigo — cool counterpart.
    static let bannerIndigo: [Color] = [
        Color(hex: "2D3A8C"),
        Color(hex: "1E2A6B"),
        Color(hex: "131C4D")
    ]
    /// Forest emerald.
    static let bannerForest: [Color] = [
        Color(hex: "2E6B3D"),
        Color(hex: "1F4F2B"),
        Color(hex: "13381C")
    ]
    /// Sunset amber.
    static let bannerSunset: [Color] = [
        Color(hex: "C77A2B"),
        Color(hex: "9A5A1B"),
        Color(hex: "6F3F10")
    ]
    /// Plum royal.
    static let bannerPlum: [Color] = [
        Color(hex: "6E2A8E"),
        Color(hex: "4F1C6B"),
        Color(hex: "36124A")
    ]
    /// Teal deep.
    static let bannerTeal: [Color] = [
        Color(hex: "1F6F7A"),
        Color(hex: "154F58"),
        Color(hex: "0B3740")
    ]

    /// The 6 bold banner gradients. Order matters: each card picks one based
    /// on its stable id so the same card always shows the same banner — that
    /// gives the screen variety without changing the user's "their card".
    static let bannerGradients: [[Color]] = [
        bannerCrimson, bannerIndigo, bannerForest,
        bannerSunset, bannerPlum, bannerTeal
    ]

    /// Pick a bold banner gradient deterministically from a card id. Using
    /// `card.id.hash` means switching languages (en ↔ zh) never changes the
    /// gradient, but every different card gets a different one.
    static func bannerForCard(id: String) -> [Color] {
        let idx = abs(id.hashValue) % bannerGradients.count
        return bannerGradients[idx]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:   (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:   (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:   (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:  (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
