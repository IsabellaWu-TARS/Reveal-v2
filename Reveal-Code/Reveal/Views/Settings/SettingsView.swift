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
    // Persisted: the reminder used to be `@State` with a default of `true`,
    // so the toggle showed ON after every launch while nothing was actually
    // scheduled (and permission had never been requested). Default is now
    // "off" — the switch tells the truth, and the choice survives relaunches.
    @AppStorage("dailyReminderEnabled") private var notificationsEnabled = false
    @AppStorage("dailyReminderHour") private var reminderHour = 20
    @AppStorage("dailyReminderMinute") private var reminderMinute = 0
    @State private var reminderTime = Date()
    @State private var showAboutSources = false
    @State private var showPrivacyPolicy = false

    // Card text colour — see CardInk.swift. Stored as a hex string so the
    // choice survives relaunch and is readable by the card views.
    @AppStorage("cardInkMode") private var cardInkMode: String = CardInk.white.rawValue
    @AppStorage("cardInkCustomHex") private var cardInkHex: String = "FFFFFF"
    @State private var customInkColor: Color = .white

    // Card colour — the whole gradient, not just the text.
    @AppStorage("cardTintMode") private var cardTintMode: String = CardTint.automatic.rawValue
    @AppStorage("cardTintTopHex") private var cardTintTopHex: String = "D6B8A8"
    @AppStorage("cardTintBottomHex") private var cardTintBottomHex: String = "C08A72"
    @State private var customTintTop: Color = Color(hex: "D6B8A8")
    @State private var customTintBottom: Color = Color(hex: "C08A72")

    // Scripture script: simplified by default, switchable to the 1919 text as
    // printed. Both renderings carry identical wording — see ScriptPreference.
    @AppStorage(ScriptPreference.key) private var scriptRaw: String = ChineseScript.simplified.rawValue

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

                                // Scripture script — only meaningful for Chinese
                                if dailyCardStore.appLanguage == "zh-Hans" {
                                    SettingsCard {
                                        VStack(alignment: .leading, spacing: 14) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "character.book.closed").foregroundColor(Design.accent)
                                                Text("经文显示")
                                                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                            }
                                            Picker("", selection: Binding(
                                                get: { ChineseScript(rawValue: scriptRaw) ?? .simplified },
                                                set: { newValue in
                                                    scriptRaw = newValue.rawValue
                                                    Task { await BibleAPIService.shared.clearCache() }
                                                }
                                            )) {
                                                ForEach(ChineseScript.allCases) { script in
                                                    Text(script.title(language: dailyCardStore.appLanguage)).tag(script)
                                                }
                                            }
                                            .pickerStyle(.segmented)

                                            Text(scriptRaw == ChineseScript.traditional.rawValue
                                                 ? "和合本 1919 年原样，繁体字形。"
                                                 : "与 1919 年原版逐字相同，仅字形转为简体。")
                                                .font(.system(size: 12, weight: .light))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                // Card Text Colour
                                SettingsCard {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "textformat").foregroundColor(Design.accent)
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "卡片文字颜色" : "Card Text Colour")
                                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                        }

                                        Menu {
                                            ForEach(CardInk.allCases) { mode in
                                                Button(mode.title(language: dailyCardStore.appLanguage)) {
                                                    cardInkMode = mode.rawValue
                                                    if mode == .custom { customInkColor = Color(hex: cardInkHex) }
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 10) {
                                                Circle()
                                                    .fill(currentInkSwatch)
                                                    .frame(width: 18, height: 18)
                                                    .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                                                Text(currentInkTitle)
                                                    .foregroundColor(Design.accent)
                                                Spacer()
                                                Image(systemName: "chevron.down").foregroundColor(Design.accent.opacity(0.6))
                                            }
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1)))
                                        }

                                        if cardInkMode == CardInk.custom.rawValue {
                                            ColorPicker(
                                                dailyCardStore.appLanguage == "zh-Hans" ? "选择颜色" : "Pick a colour",
                                                selection: $customInkColor,
                                                supportsOpacity: false
                                            )
                                            .font(.system(size: 14))
                                            .onChange(of: customInkColor) { _, newValue in
                                                cardInkHex = newValue.hexString
                                            }
                                        }

                                        Text(hintText)
                                            .font(.system(size: 12, weight: .light))
                                            .foregroundColor(Color(hex: "6B6B6B"))
                                    }
                                }

                                // Card Colour
                                SettingsCard {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "paintpalette.fill").foregroundColor(Design.accent)
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "卡片颜色" : "Card Colour")
                                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                        }

                                        Menu {
                                            ForEach(CardTint.allCases) { mode in
                                                Button(mode.title(language: dailyCardStore.appLanguage)) {
                                                    cardTintMode = mode.rawValue
                                                    if mode == .custom {
                                                        customTintTop = Color(hex: cardTintTopHex)
                                                        customTintBottom = Color(hex: cardTintBottomHex)
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 10) {
                                                Circle()
                                                    .fill(LinearGradient(colors: [currentTintTop, currentTintBottom], startPoint: .top, endPoint: .bottom))
                                                    .frame(width: 18, height: 18)
                                                    .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                                                Text(currentTintTitle)
                                                    .foregroundColor(Design.accent)
                                                Spacer()
                                                Image(systemName: "chevron.down").foregroundColor(Design.accent.opacity(0.6))
                                            }
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1)))
                                        }

                                        if cardTintMode == CardTint.custom.rawValue {
                                            ColorPicker(
                                                dailyCardStore.appLanguage == "zh-Hans" ? "上方颜色" : "Top colour",
                                                selection: $customTintTop,
                                                supportsOpacity: false
                                            )
                                            .font(.system(size: 14))
                                            .onChange(of: customTintTop) { _, newValue in
                                                cardTintTopHex = newValue.hexString
                                            }

                                            ColorPicker(
                                                dailyCardStore.appLanguage == "zh-Hans" ? "下方颜色" : "Bottom colour",
                                                selection: $customTintBottom,
                                                supportsOpacity: false
                                            )
                                            .font(.system(size: 14))
                                            .onChange(of: customTintBottom) { _, newValue in
                                                cardTintBottomHex = newValue.hexString
                                            }

                                            Button {
                                                cardTintMode = CardTint.automatic.rawValue
                                            } label: {
                                                Text(dailyCardStore.appLanguage == "zh-Hans" ? "恢复每日默认颜色" : "Reset to daily default")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(Design.accent)
                                            }
                                        }

                                        Text(tintHintText)
                                            .font(.system(size: 12, weight: .light))
                                            .foregroundColor(Color(hex: "6B6B6B"))
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
                                                    // The toggle squeezes this label on narrower
                                                    // phones and it wrapped onto two lines.
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.85)
                                            }
                                            .layoutPriority(1)
                                            Spacer()
                                            Toggle("", isOn: $notificationsEnabled)
                                                .tint(Design.accent)
                                                .onChange(of: notificationsEnabled) { _, newValue in
                                                    if newValue {
                                                        scheduleReminder(language: dailyCardStore.appLanguage)
                                                    } else {
                                                        NotificationScheduler.cancelDailyReminder()
                                                    }
                                                }
                                        }
                                        if notificationsEnabled {
                                            // Keep the time chip inside the card: the
                                            // compact picker has its own width, so it is
                                            // pinned to its ideal size and right-aligned
                                            // instead of being stretched by the VStack.
                                            HStack(spacing: 12) {
                                                Text(dailyCardStore.appLanguage == "zh-Hans" ? "提醒时间" : "Reminder time")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)
                                                Spacer(minLength: 8)
                                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                                    .labelsHidden()
                                                    .datePickerStyle(.compact)
                                                    .fixedSize()
                                                    .tint(Design.accent)
                                                    .foregroundColor(Design.accent)
                                                    .onChange(of: reminderTime) { _, _ in
                                                        scheduleReminder(language: dailyCardStore.appLanguage)
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
                                            contactLink(icon: { Image(systemName: "envelope").font(.system(size: 13)) },
                                                        text: "revealmashal@gmail.com",
                                                        url: "mailto:revealmashal@gmail.com?subject=Reveal%20Mashal%20Feedback")
                                            contactLink(icon: { instagramGlyph() },
                                                        text: "Instagram · @reveal_mashal",
                                                        url: "https://www.instagram.com/reveal_mashal")
                                            contactLink(icon: { xGlyph() },
                                                        text: "X (Twitter) · @reveal_mashal",
                                                        url: "https://x.com/reveal_mashal?s=11")
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "如有任何问题，请联系我们。" : "If you got any problems please contact us.")
                                                .font(.system(size: 12, weight: .light)).foregroundColor(Color(hex: "6B6B6B")).padding(.top, 2)
                                        }
                                    }
                                }

                                // Version — App Review and users both need this
                                // when reporting a problem.
                                SettingsCard {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.bubble.fill").foregroundColor(Design.accent)
                                        Text(dailyCardStore.appLanguage == "zh-Hans" ? "版本" : "Version")
                                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                        Spacer()
                                        Text(appVersionString)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // Privacy Policy
                                SettingsCard {
                                    Button(action: { showPrivacyPolicy = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "lock.shield.fill").foregroundColor(Design.accent)
                                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "隐私政策" : "Privacy Policy")
                                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(Design.accent.opacity(0.6))
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
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .sheet(isPresented: $showAboutSources) {
            AboutBibleSourcesSheet(language: dailyCardStore.appLanguage)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicySheet(language: dailyCardStore.appLanguage)
        }
        .onAppear {
            // Restore the saved reminder time into the picker.
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = reminderHour
            comps.minute = reminderMinute
            if let restored = Calendar.current.date(from: comps) { reminderTime = restored }

            // If it's enabled, re-assert the repeating request. Cheap and
            // idempotent — same identifier, so it replaces rather than stacks.
            if notificationsEnabled { scheduleReminder(language: dailyCardStore.appLanguage) }
        }
        .onChange(of: dailyCardStore.appLanguage) { _, newLanguage in
            // Re-schedule so the notification copy matches the chosen language.
            guard notificationsEnabled else { return }
            scheduleReminder(language: newLanguage)
        }
    }

    /// Schedules (or re-schedules) the daily reminder with the persisted time.
    private func scheduleReminder(language: String) {
        let hour = Calendar.current.component(.hour, from: reminderTime)
        let minute = Calendar.current.component(.minute, from: reminderTime)
        reminderHour = hour
        reminderMinute = minute
        Task {
            await NotificationScheduler.scheduleDailyReminder(hour: hour, minute: minute, appLanguage: language)
        }
    }

    /// "1.0 (1)" — marketing version plus build number, straight from the bundle.
    private var appVersionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    // MARK: - Card colour helpers

    private var currentTintTitle: String {
        (CardTint(rawValue: cardTintMode) ?? .automatic).title(language: dailyCardStore.appLanguage)
    }

    /// Swatch for the row: today's gradient, or the chosen colour.
    private var currentTintTop: Color {
        resolvedTint.stops.first ?? Design.paperBackground
    }
    private var currentTintBottom: Color {
        resolvedTint.stops.last ?? Design.paperBackground
    }
    private var resolvedTint: CardTintPalette {
        CardTintPalette(
            style: dailyCardStore.currentCard.map { CardStyle.forCardId($0.id) } ?? .roseDusk,
            mode: CardTint(rawValue: cardTintMode) ?? .automatic,
            topHex: cardTintTopHex,
            bottomHex: cardTintBottomHex
        )
    }

    private var tintHintText: String {
        let zh = dailyCardStore.appLanguage == "zh-Hans"
        if cardTintMode == CardTint.automatic.rawValue {
            return zh ? "每天自动更换颜色，与日期绑定。"
                      : "The card follows the daily palette — a different colour each day."
        }
        return zh ? "两种颜色会混合成 Reveal 风格的渐变，应用到所有卡片。"
                  : "Your two colours are blended into a Reveal gradient and applied to every card."
    }

    // MARK: - Card text colour helpers

    private var currentInkTitle: String {
        (CardInk(rawValue: cardInkMode) ?? .automatic).title(language: dailyCardStore.appLanguage)
    }

    private var currentInkSwatch: Color {
        switch CardInk(rawValue: cardInkMode) ?? .automatic {
        case .automatic: return Design.paperInkDeep
        case .white:     return .white
        case .ink:       return Design.paperInkDeep
        case .custom:    return Color(hex: cardInkHex)
        }
    }

    private var hintText: String {
        if dailyCardStore.appLanguage == "zh-Hans" {
            return cardInkMode == CardInk.automatic.rawValue
                ? "自动会为每张卡片挑选最易读的颜色。"
                : "浅色卡片上使用浅色文字可能难以阅读，可随时切回自动。"
        }
        return cardInkMode == CardInk.automatic.rawValue
            ? "Automatic picks the most legible ink for each card."
            : "Light ink can be hard to read on pale cards — switch back to Automatic any time."
    }

    @ViewBuilder
    private func contactLink<Icon: View>(
        @ViewBuilder icon: () -> Icon,
        text: String,
        url: String
    ) -> some View {
        if let u = URL(string: url) {
            Link(destination: u) {
                HStack(spacing: 8) {
                    icon()
                        .foregroundColor(Design.accent)
                        .frame(width: 16, height: 16)
                    Text(text).font(.system(size: 14)).foregroundColor(Design.accent)
                }
            }
        }
    }

    /// Instagram's camera glyph. SF Symbols carries no brand marks, and a bare
    /// `camera.fill` read as "take a photo", so the rounded-square outline is
    /// drawn here at the same 16pt box the other icons occupy.
    private func instagramGlyph(_ size: CGFloat = 16) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .strokeBorder(Design.accent, lineWidth: 1.4)
            Circle()
                .strokeBorder(Design.accent, lineWidth: 1.4)
                .frame(width: size * 0.42, height: size * 0.42)
            Circle()
                .fill(Design.accent)
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: size * 0.24, y: -size * 0.24)
        }
        .frame(width: size, height: size)
    }

    /// X's wordmark, drawn as two crossed strokes ("xmark" would read as a
    /// close button, and "at" read as an email alias).
    private func xGlyph(_ size: CGFloat = 16) -> some View {
        ZStack {
            Rectangle().fill(Design.accent)
                .frame(width: size * 0.92, height: 1.7)
                .rotationEffect(.degrees(45))
            Rectangle().fill(Design.accent)
                .frame(width: size * 0.92, height: 1.7)
                .rotationEffect(.degrees(-45))
        }
        .frame(width: size, height: size)
    }
}

struct SettingsCard<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        // In dark mode, use translucent BLACK (so it's visible against the
        // dark AppBackground) instead of translucent white (which blends
        // invisibly into the dark background).
        let bgFill: Color = (colorScheme == .dark)
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.65)
        let borderStroke: Color = (colorScheme == .dark)
            ? Color.white.opacity(0.15)
            : Color.black.opacity(0.08)
        return VStack(alignment: .leading, spacing: 0) { content }
            .padding(18)
            // Cards used to size to their content, so "Contact Us" (short
            // link rows) came out narrower than the others and looked
            // off-centre. Every card now spans the column.
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(bgFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(borderStroke, lineWidth: 1)
                    )
            )
    }
}
