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
    @State private var step: Int = 0

    private var lang: String { dailyCardStore.appLanguage }
    private var currentCard: RevealCard? { dailyCardStore.cardForOnboarding(at: 0) }

    // BUG FIX (P0-1): Previously only English strings were provided, so Chinese
    // users saw English tutorials. Now we pick the right array based on appLanguage.
    private let stepTextsEN = [
        "Tap the card to turn it over — the verse is on the front, the reflection and one small action are on the back.",
        "The calendar keeps every day you have read. Tap a past day to open it again.",
        "Tap the note button to write your reflection. It saves itself as you type.",
        "Read the whole chapter from the book button. In Settings you can turn on a daily reminder, or choose your own card and text colours."
    ]

    private let stepTextsZH = [
        "轻点卡片翻面 —— 正面是经文，背面是反思和一个小行动。",
        "日历会记下你读过的每一天，点开过去的日期就能重读。",
        "点笔记按钮写下你的感想，边写边自动保存。",
        "用书页按钮阅读整章经文；在设置里可以开启每日提醒，或自定义卡片与文字颜色。"
    ]

    /// Real top inset of the window. The page ZStack reports zero insets
    /// because `AppBackground` ignores the safe area, which left "Skip" under
    /// the status bar.
    private var windowTopInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first?.safeAreaInsets.top ?? 47
    }

    private var buttonTitle: String {
        let last = step >= stepTexts.count - 1
        if lang == "zh-Hans" { return last ? "开始体验" : "下一步" }
        return last ? "Get Started" : "Next"
    }

    private var stepTexts: [String] {
        lang == "zh-Hans" ? stepTextsZH : stepTextsEN
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack {
                Spacer(minLength: windowTopInset)

                Spacer()

                if let card = currentCard {
                    OnboardingCardDemo(
                        card: card,
                        cardFlipped: $cardFlipped,
                        rotation: $rotation,
                        lang: lang
                    )
                    .frame(maxWidth: .infinity, maxHeight: 430)
                }

                TutorialBubble(text: stepTexts[min(step, stepTexts.count - 1)])
                    .id(step)
                    .transition(.opacity)
                    .padding(.top, 10)

                // Page dots — four short steps, nothing to scroll.
                HStack(spacing: 8) {
                    ForEach(0..<stepTexts.count, id: \.self) { index in
                        Circle()
                            .fill(index == step ? Design.accent : Design.accent.opacity(0.25))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 14)

                HStack(spacing: 16) {
                    Button(lang == "zh-Hans" ? "跳过" : "Skip") {
                        withAnimation { showOnboarding = false }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Design.accent.opacity(0.7))

                    Spacer(minLength: 0)

                    Button(buttonTitle) {
                        if step >= stepTexts.count - 1 {
                            withAnimation { showOnboarding = false }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) { step += 1 }
                        }
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                }
                .padding(.horizontal, 32)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .padding(.bottom, 10)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
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
