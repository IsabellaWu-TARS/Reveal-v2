//
//  Shapes.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct AppBackground: View {
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            if isDark {
                LinearGradient(colors: [Color(hex: "1E1E1E"), Color(hex: "111111")], startPoint: .top, endPoint: .bottom)
            } else {
                // P8: page-level paper cream (slightly darker than the card
                // surface so the card stands out). Keeps the "open Bible
                // on parchment" feel.
                Design.paperBackground
            }
            Image(systemName: "leaf.fill")
                .resizable().aspectRatio(contentMode: .fit).frame(width: 450, height: 450)
                .foregroundColor(Design.accent.opacity(isDark ? 0.04 : 0.06))
                .blur(radius: isDark ? 20 : 30)
                .offset(x: -100, y: -280)
        }
        .ignoresSafeArea()
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.95))
        p.addCurve(to: CGPoint(x: w * 0.2, y: h * 0.3), control1: CGPoint(x: w * 0.35, y: h * 0.7), control2: CGPoint(x: w * 0.25, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.05), control1: CGPoint(x: w * 0.3, y: h * 0.15), control2: CGPoint(x: w * 0.4, y: h * 0.08))
        p.addCurve(to: CGPoint(x: w * 0.8, y: h * 0.3), control1: CGPoint(x: w * 0.6, y: h * 0.08), control2: CGPoint(x: w * 0.7, y: h * 0.15))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.95), control1: CGPoint(x: w * 0.75, y: h * 0.5), control2: CGPoint(x: w * 0.65, y: h * 0.7))
        p.closeSubpath()
        return p
    }
}

struct LeafVeinsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.95)); p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.05))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.4)); p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.35))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.5)); p.addLine(to: CGPoint(x: w * 0.28, y: h * 0.45))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.6)); p.addLine(to: CGPoint(x: w * 0.32, y: h * 0.65))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.4)); p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.35))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.5)); p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.45))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.6)); p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.65))
        return p
    }
}
