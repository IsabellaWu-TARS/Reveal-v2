//
//  OnboardingView.swift
//  Reveal
//
//  First-run flow:
//
//    1. Pick a language — the leaf from the splash, two cards, one tap.
//    2. Four coach marks drawn on the real home screen. The guide is an overlay:
//       the page underneath is HomeView itself, at its normal size, with the
//       card and every button where they actually sit. Each control publishes
//       its bounds (CoachAnchors), so the ring and the note land on the real
//       button rather than a reconstruction of it.
//

import SwiftUI
import UIKit

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var dailyCardStore: DailyCardStore

    @State private var stage: Stage = .language
    @State private var step: Int = 0

    enum Stage { case language, guide }

    private var lang: String { dailyCardStore.appLanguage }
    private var isZH: Bool { lang == "zh-Hans" }

    private let targets: [CoachTarget] = [.read, .calendar, .notes, .settings]
    private var target: CoachTarget { targets[min(step, targets.count - 1)] }

    private var title: String {
        switch target {
        case .read:     return isZH ? "读整章" : "Read the chapter"
        case .calendar: return isZH ? "日历" : "Calendar"
        case .notes:    return isZH ? "笔记" : "Notes"
        case .settings: return isZH ? "设置" : "Settings"
        }
    }

    private var detail: String {
        switch target {
        case .read:
            return isZH ? "点这里，阅读今天经文所在的完整章节。" : "Opens the full chapter this verse comes from."
        case .calendar:
            return isZH ? "你读过的每一天都在这里，点开就能重读。" : "Every day you have read, ready to open again."
        case .notes:
            return isZH ? "写下你的感想，边写边自动保存。" : "Write your reflection — it saves itself."
        case .settings:
            return isZH ? "开启每日提醒，或自选卡片与文字颜色。" : "Daily reminder, and your own card and text colours."
        }
    }

    /// Real top inset: the page ZStack reports zero because AppBackground
    /// ignores the safe area.
    private var topInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first?.safeAreaInsets.top ?? 47
    }

    var body: some View {
        Group {
            switch stage {
            case .language: languageStep
            case .guide:    guideStep
            }
        }
        .animation(.easeInOut(duration: 0.25), value: stage)
    }

    // MARK: - Step 1 · language

    private var languageStep: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                Image("SplashLeaf")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
                    .shadow(color: Color(hex: "A2A569").opacity(0.35), radius: 22, x: 0, y: 8)
                    .padding(.bottom, 20)

                VStack(spacing: 8) {
                    Text("Choose your language")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("选择你的语言")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)

                VStack(spacing: 14) {
                    languageCard(code: "en", label: "English", sample: "A verse a day")
                    languageCard(code: "zh-Hans", label: "简体中文", sample: "每天一节经文")
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 16)

                Text(isZH ? "之后可在设置中更改" : "You can change this later in Settings")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 28)
            }
            .padding(.top, topInset)
        }
    }

    private func languageCard(code: String, label: String, sample: String) -> some View {
        Button {
            dailyCardStore.setLanguage(code)
            withAnimation { stage = .guide }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    // Fixed ink: the card is always cream, in either appearance,
                    // so `.primary` would vanish in dark mode.
                    Text(label)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2A2A2A"))
                    Text(sample)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color(hex: "6B6B6B"))
                }
                Spacer()
                Image(systemName: dailyCardStore.appLanguage == code
                      ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: dailyCardStore.appLanguage == code ? 20 : 14))
                    .foregroundColor(Design.accent.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "FAF7F2"))
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier("language-\(code)")
    }

    // MARK: - Step 2 · coach marks over the real page

    private var guideStep: some View {
        // The real home screen, at its normal size, frozen behind the overlay.
        HomeView(currentPage: .constant(.home))
            .allowsHitTesting(false)
            .overlayPreferenceValue(CoachAnchorKey.self) { anchors in
                GeometryReader { proxy in
                    if let anchor = anchors[target] {
                        let rect = proxy[anchor]
                        coachLayer(rect: rect, screen: proxy.size)
                    }
                }
            }
    }

    private func coachLayer(rect: CGRect, screen: CGSize) -> some View {
        // A square ring around a square button; the wide Notes pill keeps its
        // shape instead of becoming a giant square.
        let holeWidth = rect.width + 28
        let holeHeight = min(rect.height + 28, holeWidth)
        let hole = CGRect(x: rect.midX - holeWidth / 2,
                          y: rect.midY - holeHeight / 2,
                          width: holeWidth,
                          height: holeHeight)
        let above = rect.midY > screen.height * 0.5
        let noteWidth = min(screen.width - 44, 340)
        let noteHeight: CGFloat = 168
        let noteY = above
            ? hole.minY - 14 - noteHeight / 2
            : hole.maxY + 14 + noteHeight / 2
        let noteX = min(max(rect.midX, noteWidth / 2 + 16), screen.width - noteWidth / 2 - 16)

        return ZStack {
            // Dim everything except the control being explained.
            Rectangle()
                .fill(Color.black.opacity(0.42))
                .mask(
                    Rectangle()
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .frame(width: hole.width, height: hole.height)
                                .position(x: hole.midX, y: hole.midY)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                )
                // No .ignoresSafeArea() here: stretching the mask would scale
                // the cut-out away from the control it is supposed to reveal.
                .frame(width: screen.width, height: screen.height)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Design.accent, lineWidth: 2.5)
                .frame(width: hole.width, height: hole.height)
                .position(x: hole.midX, y: hole.midY)
                .shadow(color: Design.accent.opacity(0.45), radius: 14)

            // Arrow between the note and the control it points at.
            Image(systemName: above ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
                .font(.system(size: 18))
                .foregroundColor(Design.accent)
                .position(x: min(max(rect.midX, noteX - noteWidth / 2 + 20), noteX + noteWidth / 2 - 20),
                          y: above ? noteY + noteHeight / 2 + 12 : noteY - noteHeight / 2 - 12)

            coachNote
                .frame(width: noteWidth, height: noteHeight)
                .position(x: noteX, y: noteY)
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private var coachNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "2A2A2A"))
            Text(detail)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "5C5C5C"))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                ForEach(0..<targets.count, id: \.self) { index in
                    Circle()
                        .fill(index == step ? Design.accent : Design.accent.opacity(0.25))
                        .frame(width: 6, height: 6)
                }

                Spacer(minLength: 0)

                Button(isZH ? "跳过" : "Skip") {
                    withAnimation { showOnboarding = false }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Design.accent.opacity(0.75))

                Button(buttonTitle) {
                    if step >= targets.count - 1 {
                        withAnimation { showOnboarding = false }
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) { step += 1 }
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Capsule().fill(Design.accent))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "FAF7F2"))
                .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 8)
        )
    }

    private var buttonTitle: String {
        let last = step >= targets.count - 1
        if isZH { return last ? "开始体验" : "下一步" }
        return last ? "Get Started" : "Next"
    }
}

#Preview {
    ContentView()
}
