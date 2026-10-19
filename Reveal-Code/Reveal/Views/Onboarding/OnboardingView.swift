//
//  OnboardingView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @State private var cardFlipped = false
    @State private var rotation: Double = 0

    private var lang: String { dailyCardStore.appLanguage }
    private var currentCard: RevealCard? { dailyCardStore.cardForOnboarding(at: 0) }

    // BUG FIX (P0-1): Previously only English strings were provided, so Chinese
    // users saw English tutorials. Now we pick the right array based on appLanguage.
    private let stepTextsEN = [
        "Here is the verse of the day. Tap the card to reveal reflection.",
        "Tap to see the reflection question and action step.",
        "Tap the Bible icon to read the full passage.",
        "Tap Calendar to revisit all verses you've studied.",
        "Tap Note to write your personal reflection. It saves automatically.",
        "Start your journey now!"
    ]

    private let stepTextsZH = [
        "这是今日经文。点击卡片查看反思内容。",
        "再次点击卡片，查看反思问题与行动建议。",
        "点击左上角圣经图标，查看完整章节。",
        "点击日历图标，回顾你学习过的所有经文。",
        "点击笔记按钮，写下你的个人反思（自动保存）。",
        "开启你的灵修之旅吧！"
    ]

    private var stepTexts: [String] {
        lang == "zh-Hans" ? stepTextsZH : stepTextsEN
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack {
                HStack {
                    Spacer()
                    Button(lang == "zh-Hans" ? "跳过" : "Skip") {
                        withAnimation { showOnboarding = false }
                    }
                    .foregroundColor(Design.accent.opacity(0.6))
                    .padding()
                }

                Spacer()

                if let card = currentCard {
                    OnboardingCardDemo(
                        card: card,
                        cardFlipped: $cardFlipped,
                        rotation: $rotation,
                        lang: lang
                    )
                }

                TutorialBubble(text: stepTexts[0])
                    .padding(.bottom, 44)

                HStack(spacing: 20) {
                    Button(lang == "zh-Hans" ? "开始体验" : "Get Started") {
                        withAnimation { showOnboarding = false }
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingCardDemo: View {
    let card: RevealCard
    @Binding var cardFlipped: Bool
    @Binding var rotation: Double
    let lang: String
    @State private var cardDayIndex: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Bible button with arrow pointing down to it
                ZStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Design.accent)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.7)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))

                    // Arrow below the Bible button
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Design.accent)
                        .offset(y: 36)
                        .opacity(0.8)
                }
                Spacer()
                // Calendar button
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Design.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.7)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)

            Spacer()

            ZStack {
                // BUG FIX (P0-2): The flip direction was inverted compared to
                // HomeView (the canonical reference). In HomeView:
                //   Front  -> rotation(transitionAngle)
                //   Back   -> rotation(transitionAngle - 180)
                // The onboarding had the two views swapped, which made the
                // card appear to spin the wrong way. Aligning now.
                CardBackView(
                    card: card, language: lang,
                    style: .roseDusk,
                    onFavorite: {}, isFavorite: false
                )
                    .opacity(cardFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(rotation - 180), axis: (x: 0, y: 1, z: 0), perspective: 0.5)

                CardFrontView(
                    card: card, language: lang,
                    style: .roseDusk,
                    onFavorite: {}, isFavorite: false
                )
                .opacity(cardFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .padding(.horizontal, 24)
            .onTapGesture {
                withAnimation(Design.springAnim) {
                    cardFlipped.toggle()
                    rotation += 180
                }
            }

            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Design.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.7)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))

                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Design.accent)
                    .offset(x: -44, y: -30)
                    .opacity(0.8)
            }
            .padding(.top, 16)

            Spacer()
        }
        .opacity(0.9)
    }
}

struct TutorialBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color(hex: "2A2A2A"))
            .multilineTextAlignment(.center)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "FAF7F2")).shadow(color: Color.black.opacity(0.12), radius: 10))
            .padding(.horizontal, 32)
    }
}

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 36).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 22).fill(Design.accent))
            .foregroundColor(.white)
            .font(.system(size: 15, weight: .bold))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView()
}
