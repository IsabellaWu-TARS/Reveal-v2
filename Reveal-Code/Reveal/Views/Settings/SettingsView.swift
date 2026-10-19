//
//  SettingsView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct SettingsView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @State private var notificationsEnabled = true
    @State private var reminderTime = Date()
    @State private var showAboutSources = false

    var body: some View {
        // P13: Pull the Settings cards toward the centre so the frame reads
        // tighter (per user feedback: "可以往中间紧凑一点"). We cap the scroll
        // content width to ~82% of the screen — the same ratio used by the
        // home card — so on every iPhone the Settings cards form a single
        // visually-balanced centred column, with extra breathing room on
        // both sides. The top header bar (back button + "Settings" title)
        // still uses the full Design.horizontalPadding so the nav chrome
        // stays exactly where it is.
        //
        // P13b fix (user feedback: "让左右两边距离屏幕的尺寸保持一致"):
        // instead of the centering-via-frame trick (which can drift due to
        // safe-area / GeometryReader quirks), and the later
        // .padding(.horizontal, sideMargin) trick (which can still be
        // absorbed by the parent ZStack's centre alignment), we now wrap
        // the column in an explicit HStack { Spacer; column; Spacer }.
        // SwiftUI splits the available width into two equal halves, so
        // left margin == right margin on every device, every iOS version.
        GeometryReader { geo in
            let screenW = geo.size.width
            let contentMaxW = min(screenW * 0.82, 340)
            ZStack {
                AppBackground()
                VStack(spacing: 0) {
                    HStack {
                        BackCircleButton { withAnimation { currentPage = .home } }
                        Spacer()
                        Text("Settings")
                            .font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                        Spacer()
                        Color.clear.frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                    }
                    .padding(.horizontal, Design.horizontalPadding)
                    .padding(.top, 16)

                    ScrollView {
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            VStack(spacing: 16) {
                                // Appearance
                                SettingsCard {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "circle.lefthalf.filled").foregroundColor(Design.accent)
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "外观" : "Appearance")
                                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                        }
                                        Picker("", selection: $themeManager.appearanceMode) {
                                            ForEach(ThemeManager.AppearanceMode.allCases, id: \.self) { mode in
                                                Text(mode.title(for: dailyCardStore.appLanguage)).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                }

                                // Language
                                SettingsCard {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "globe").foregroundColor(Design.accent)
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "语言" : "Language")
                                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                        }
                                        Menu {
                                            Button("English") { dailyCardStore.setLanguage("en") }
                                            Button("中文") { dailyCardStore.setLanguage("zh-Hans") }
                                        } label: {
                                            HStack {
                                                Text(dailyCardStore.appLanguage == "zh-Hans" ? "中文" : "English")
                                                    .foregroundColor(Design.accent)
                                                Spacer()
                                                Image(systemName: "chevron.down").foregroundColor(Design.accent.opacity(0.6))
                                            }
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1)))
                                        }
                                    }
                                }

                                // Daily Reminders
                                SettingsCard {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack {
                                            HStack(spacing: 8) {
                                                Image(systemName: "bell.fill").foregroundColor(Design.accent)
                                                Text(dailyCardStore.appLanguage == "zh-Hans" ? "每日提醒" : "Daily Reminders")
                                                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                            }
                                            Spacer()
                                            Toggle("", isOn: $notificationsEnabled)
                                                .tint(Design.accent)
                                                .onChange(of: notificationsEnabled) { _, newValue in
                                                    if newValue {
                                                        let hour = Calendar.current.component(.hour, from: reminderTime)
                                                        let minute = Calendar.current.component(.minute, from: reminderTime)
                                                        Task {
                                                            await NotificationScheduler.scheduleDailyReminder(hour: hour, minute: minute, appLanguage: dailyCardStore.appLanguage)
                                                        }
                                                    } else {
                                                        NotificationScheduler.cancelDailyReminder()
                                                    }
                                                }
                                        }
                                        if notificationsEnabled {
                                            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                                .datePickerStyle(.compact)
                                                .tint(Design.accent)
                                                .foregroundColor(Design.accent)
                                                .onChange(of: reminderTime) { _, newValue in
                                                    let hour = Calendar.current.component(.hour, from: newValue)
                                                    let minute = Calendar.current.component(.minute, from: newValue)
                                                    Task {
                                                        await NotificationScheduler.scheduleDailyReminder(hour: hour, minute: minute, appLanguage: dailyCardStore.appLanguage)
                                                    }
                                                }
                                        }
                                    }
                                }

                                // Contact Us
                                SettingsCard {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "envelope.fill").foregroundColor(Design.accent)
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "联系我们" : "Contact Us")
                                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                        }
                                        VStack(alignment: .leading, spacing: 10) {
                                            contactLink(icon: "envelope", text: "revealmashal@gmail.com", url: "mailto:revealmashal@gmail.com?subject=Reveal%20Mashal%20Feedback")
                                            contactLink(icon: "camera.fill", text: "@reveal_mashal", url: "https://www.instagram.com/reveal_mashal")
                                            contactLink(icon: "at", text: "X (Twitter)", url: "https://x.com/reveal_mashal?s=11")
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "如有任何问题，请联系我们。" : "If you got any problems please contact us.")
                                                .font(.system(size: 12, weight: .light)).foregroundColor(Color(hex: "6B6B6B")).padding(.top, 2)
                                        }
                                    }
                                }

                                // About Bible Sources
                                SettingsCard {
                                    Button(action: { showAboutSources = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "info.circle.fill").foregroundColor(Design.accent)
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "资料来源与版权声明" : "About Bible Sources")
                                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(Design.accent.opacity(0.6))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: contentMaxW)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAboutSources) {
            AboutBibleSourcesSheet(language: dailyCardStore.appLanguage)
        }
    }

    @ViewBuilder
    private func contactLink(icon: String, text: String, url: String) -> some View {
        if let u = URL(string: url) {
            Link(destination: u) {
                HStack(spacing: 8) {
                    Image(systemName: icon).foregroundColor(Design.accent)
                    Text(text).font(.system(size: 14)).foregroundColor(Design.accent)
                }
            }
        }
    }
}

struct SettingsCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1)))
    }
}
