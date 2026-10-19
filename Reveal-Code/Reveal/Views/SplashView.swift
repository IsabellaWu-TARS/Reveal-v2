//
//  SplashView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct SplashView: View {
    @Binding var showSplash: Bool
    let isFirstLaunch: Bool
    let onFirstLaunchComplete: () -> Void

    @State private var opacityText: Double = 0
    @State private var scaleText: CGFloat = 0.7
    @State private var opacityIcon: Double = 0
    @State private var scaleIcon: CGFloat = 0.7

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if isFirstLaunch {
                // First screen: welcome text
                VStack(spacing: 16) {
                    Text("Welcome To")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Design.accent)
                    Text("Reveal Mashal")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                .opacity(opacityText)
                .scaleEffect(scaleText)
            } else {
                // Normal splash: app icon
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(LinearGradient(colors: [Color(hex: "E8F5E9"), Color(hex: "C8E6C9")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 160)
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Design.accent.opacity(0.5), lineWidth: 2))
                        .shadow(color: Color(hex: "4CAF50").opacity(0.2), radius: 20)

                    LeafShape()
                        .fill(LinearGradient(colors: [Design.accent, Color(hex: "B8C48A"), Color(hex: "A8B89A")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 110)
                        .overlay(LeafVeinsShape().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                        .overlay(Text("R").font(.custom("Georgia", size: 44)).fontWeight(.bold).foregroundColor(Color.white.opacity(0.95)).offset(x: 0, y: -6))
                }
                .opacity(opacityIcon)
                .scaleEffect(scaleIcon)
            }
        }
        .onAppear {
            if isFirstLaunch {
                withAnimation(.easeOut(duration: 0.8)) { opacityText = 1.0; scaleText = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) { opacityText = 0; scaleText = 1.1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.8)) { opacityIcon = 1.0; scaleIcon = 1.0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) { opacityIcon = 0; scaleIcon = 0.9 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onFirstLaunchComplete()
                                withAnimation { showSplash = false }
                            }
                        }
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.6)) { opacityIcon = 1.0; scaleIcon = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) { opacityIcon = 0; scaleIcon = 0.9 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showSplash = false }
                }
            }
        }
    }
}
