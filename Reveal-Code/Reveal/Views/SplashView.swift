//
//  SplashView.swift
//  Reveal
//
//  Launch screen: the watercolour leaf (the app-icon art) pops in, breathes
//  like a loading indicator, then hands over to the app. The backdrop follows
//  the system appearance — warm paper in light mode, near-black in dark mode.
//

import SwiftUI
import Combine
import UIKit

struct SplashView: View {
    @Binding var showSplash: Bool
    let isFirstLaunch: Bool
    let onFirstLaunchComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Animation drivers.
    @State private var leafAppeared = false     // pop-in from small + fade
    @State private var leafBreathing = false    // the "loading" pulse
    @State private var isLeaving = false        // fade-out into the app

    private var isDark: Bool { colorScheme == .dark }

    /// Final vertical position of the leaf: 46pt above dead centre.
    private static let restingOffset: CGFloat = -46

    /// Warm paper in light mode, near-black in dark mode.
    private var backdrop: LinearGradient {
        isDark
            ? LinearGradient(colors: [Color(hex: "141310"), Color(hex: "0B0A08")],
                             startPoint: .top, endPoint: .bottom)
            : LinearGradient(colors: [Color(hex: "FFFBF0"), Color(hex: "F5EDDC")],
                             startPoint: .top, endPoint: .bottom)
    }

    /// Soft halo behind the leaf so it sits on the page instead of floating.
    private var haloColor: Color {
        Color(hex: "A2A569").opacity(isDark ? 0.16 : 0.18)
    }

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            Circle()
                .fill(haloColor)
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .opacity(leafAppeared ? 1 : 0)

            // The leaf alone — no wordmark. Sits a touch above true centre so
            // it reads as "resting" rather than floating mid-screen.
            Image("SplashLeaf")
                .resizable()
                .scaledToFit()
                .frame(width: 230, height: 230)
                .shadow(color: Color.black.opacity(isDark ? 0.45 : 0.12), radius: 24, x: 0, y: 12)
                // Pop in: small + transparent → full size, then breathe.
                .scaleEffect(leafAppeared ? (leafBreathing ? 1.05 : 0.98) : 0.55)
                .opacity(leafAppeared ? 1 : 0)
                .offset(y: leafAppeared ? Self.restingOffset : Self.restingOffset + 20)
                // Leaving: lifts and fades as the app appears.
                .scaleEffect(isLeaving ? 1.08 : 1)
                .opacity(isLeaving ? 0 : 1)
        }
        .task {
            // 1 — pop in.
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                leafAppeared = true
            }

            // 2 — breathe while the app warms up (gentle 0.98 ↔ 1.05 loop).
            try? await Task.sleep(for: .milliseconds(520))
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                leafBreathing = true
            }

            // 3 — hold long enough to read as "loading", then hand over.
            try? await Task.sleep(for: .milliseconds(isFirstLaunch ? 1500 : 1350))
            if isFirstLaunch { onFirstLaunchComplete() }
            withAnimation(.easeInOut(duration: 0.45)) { isLeaving = true }
            try? await Task.sleep(for: .milliseconds(420))
            showSplash = false
        }
    }
}
