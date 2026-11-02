//
//  OnboardingView.swift
//  Reveal
//
//  First-run flow, kept deliberately small:
//
//    1. Pick a language — two cards, one tap, applies immediately.
//    2. Four coach marks. Each highlights a real control of the home screen
//       (book, calendar, note, settings) with an arrow aimed at it and a
//       one-line label, so the guide points at the app rather than describing it.
//
//  No demo card sits in the middle of this flow: the guide is the only thing on
//  screen, so nothing competes with it or pushes it off a small phone.
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

    private struct Coach {
        let icon: String
        let title: String
        let detail: String
        let corner: Corner
        enum Corner { case topLeft, topRight, bottomLeft, bottomRight }
    }

    private var coaches: [Coach] {
        if isZH {
            return [
                Coach(icon: "book.fill",
                      title: "读整章",
                      detail: "点这里，阅读今天经文所在的完整章节。",
                      corner: .topLeft),
                Coach(icon: "calendar",
                      title: "日历",
                      detail: "你读过的每一天都在这里，点开就能重读。",
                      corner: .topRight),
                Coach(icon: "note.text",
                      title: "笔记",
                      detail: "写下你的感想，边写边自动保存。",
                      corner: .bottomLeft),
                Coach(icon: "gearshape.fill",
                      title: "设置",
                      detail: "开启每日提醒，或自选卡片与文字颜色。",
                      corner: .bottomRight)
            ]
        }
        return [
            Coach(icon: "book.fill",
                  title: "Read the chapter",
                  detail: "Opens the full chapter this verse comes from.",
                  corner: .topLeft),
            Coach(icon: "calendar",
                  title: "Calendar",
                  detail: "Every day you have read, ready to open again.",
                  corner: .topRight),
            Coach(icon: "note.text",
                  title: "Notes",
                  detail: "Write your reflection — it saves itself.",
                  corner: .bottomLeft),
            Coach(icon: "gearshape.fill",
                  title: "Settings",
                  detail: "Daily reminder, and your own card and text colours.",
                  corner: .bottomRight)
        ]
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
        ZStack {
            AppBackground()

            switch stage {
            case .language: languageStep
            case .guide:    guideStep
            }
        }
        .padding(.top, topInset)
        .animation(.easeInOut(duration: 0.25), value: stage)
    }

    // MARK: - Step 1 · language

    private var languageStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 8) {
                Text("Choose your language")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Text("选择你的语言")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)

            VStack(spacing: 14) {
                languageCard(code: "en", label: "English", sample: "A verse a day")
                languageCard(code: "zh-Hans", label: "简体中文", sample: "每天一节经文")
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 20)

            Text(isZH ? "之后可在设置中更改" : "You can change this later in Settings")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.secondary)
                .padding(.bottom, 28)
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

    // MARK: - Step 2 · coach marks

    private var guideStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            coachMap
                .padding(.horizontal, 32)

            Spacer(minLength: 12)

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<coaches.count, id: \.self) { index in
                        Circle()
                            .fill(index == step ? Design.accent : Design.accent.opacity(0.22))
                            .frame(width: 7, height: 7)
                    }
                }

                HStack(spacing: 16) {
                    Button(isZH ? "跳过" : "Skip") {
                        withAnimation { showOnboarding = false }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Design.accent.opacity(0.7))

                    Spacer(minLength: 0)

                    Button(buttonTitle) {
                        if step >= coaches.count - 1 {
                            withAnimation { showOnboarding = false }
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) { step += 1 }
                        }
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 26)
        }
    }

    /// Four chips arranged like the home screen's controls, with the current one
    /// filled and an arrow from the explanation card pointing at it.
    private var coachMap: some View {
        let current = coaches[min(step, coaches.count - 1)]
        return VStack(spacing: 0) {
            HStack {
                coachChip(coaches[0], isActive: current.corner == .topLeft)
                    .accessibilityIdentifier("coach-book")
                Spacer()
                coachChip(coaches[1], isActive: current.corner == .topRight)
                    .accessibilityIdentifier("coach-calendar")
            }

            HStack(alignment: .center, spacing: 6) {
                if current.corner == .topRight || current.corner == .bottomRight {
                    Spacer(minLength: 0)
                }

                // The arrow always sits on the outer side of the card, between
                // it and the chip it is pointing at.
                switch current.corner {
                case .topLeft, .bottomLeft:
                    arrow(for: current.corner)
                    explanationCard(current)
                    Spacer(minLength: 0)
                case .topRight, .bottomRight:
                    Spacer(minLength: 0)
                    explanationCard(current)
                    arrow(for: current.corner)
                }
            }
            .padding(.vertical, 14)

            HStack {
                coachChip(coaches[2], isActive: current.corner == .bottomLeft)
                    .accessibilityIdentifier("coach-note")
                Spacer()
                coachChip(coaches[3], isActive: current.corner == .bottomRight)
                    .accessibilityIdentifier("coach-settings")
            }
        }
    }

    private func explanationCard(_ coach: Coach) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(coach.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "2A2A2A"))
            Text(coach.detail)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "5C5C5C"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: 250, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "FAF7F2"))
                .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 5)
        )
    }

    private func arrow(for corner: Coach.Corner) -> some View {
        Image(systemName: arrowName(for: corner))
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(Design.accent)
    }

    private func coachChip(_ coach: Coach, isActive: Bool) -> some View {
        Image(systemName: coach.icon)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(isActive ? .white : Design.accent)
            .frame(width: isActive ? 56 : 44, height: isActive ? 56 : 44)
            .background(
                Circle()
                    .fill(isActive ? Design.accent : Color(hex: "FAF7F2"))
                    .shadow(color: Color.black.opacity(isActive ? 0.18 : 0.06),
                            radius: isActive ? 10 : 5, x: 0, y: 3)
            )
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private func arrowName(for corner: Coach.Corner) -> String {
        switch corner {
        case .topLeft:     return "arrow.up.left"
        case .topRight:    return "arrow.up.right"
        case .bottomLeft:  return "arrow.down.left"
        case .bottomRight: return "arrow.down.right"
        }
    }

    private var buttonTitle: String {
        let last = step >= coaches.count - 1
        if isZH { return last ? "开始体验" : "下一步" }
        return last ? "Get Started" : "Next"
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
