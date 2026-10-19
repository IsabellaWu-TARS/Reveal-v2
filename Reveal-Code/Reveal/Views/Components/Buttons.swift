//
//  Buttons.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct BottomBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Design.accent)
                    // BUG FIX (P5): icon hit-target now scales with the
                    // device so the bottom bar looks consistent from SE
                    // to Pro Max.
                    .frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                    .background(
                        Circle()
                            .fill(isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.7))
                            .shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3)
                    )
                Text(label)
                    .font(.system(size: Design.bottomBarLabelSize, weight: .medium))
                    .foregroundColor(isDark ? Color.white.opacity(0.6) : Color(hex: "6B6B6B"))
            }
        }
    }
}

struct HomeCircleButton: View {
    let icon: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Design.accent)
                // BUG FIX (P5): respond to screen size.
                .frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                .background(
                    Circle()
                        .fill(isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.6))
                        .shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3)
                )
        }
    }
}

struct FavoriteButton: View {
    let isFavorite: Bool
    let onTap: () -> Void
    @State private var scale: CGFloat = 1.0

    var body: some View {
        // P11: We render the star on a soft paper-cream chip so it stays
        // visible on top of ANY banner gradient (crimson, indigo, forest,
        // etc.). The chip background is light cream; the star inside is
        // either the design accent (when unstarred) or warm gold (starred).
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.4 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.0 }
            }
            onTap()
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isFavorite ? Color(hex: "E2A12B") : Design.paperInkMuted)
                .scaleEffect(scale)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                )
        }
    }
}

struct BackCircleButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Design.accent)
                // BUG FIX (P5): 44pt was fine on 17 Pro but felt tiny on
                // 17 Pro Max. Now uses Design.iconButtonSize (44 / 52).
                .frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                .background(Circle().fill(isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.6)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))
        }
    }
}

struct BackToHomeButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                Text("Back to Home")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(hex: "2A2A2A"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "FAF7F2")).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.08), lineWidth: 1)).shadow(color: Design.cardShadowColor, radius: 8))
        }
    }
}
