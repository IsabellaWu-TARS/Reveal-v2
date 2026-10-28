//
//  PrivacyPolicySheet.swift
//  Reveal
//
//  In-app privacy policy. App Store Review Guideline 5.1.1(i) requires every
//  app to link its privacy policy both in App Store Connect *and* in the app
//  in an easily accessible manner, and the policy must explicitly state:
//
//    (a) what data is collected, how, and every use of it
//    (b) that any third party receiving user data offers equal protection
//    (c) the retention/deletion policy, and how consent is withdrawn or
//        deletion requested
//
//  Everything below is written to match what this build actually does:
//
//    Network ................ one GET to bible.helloao.org per chapter opened
//                             (no identifiers) + Apple push for the reminder
//    Servers ................ none of ours
//    Accounts ............... none
//    SDKs ................... none
//    App Privacy label ...... "Data Not Collected" (nothing leaves the device
//                             in a form we can read; notes and favourites are
//                             only ever in UserDefaults)
//
//  Keep this text in sync with `Privacy/privacy.html` and with the App Privacy
//  answers in App Store Connect. If you host the HTML somewhere, put the URL
//  in `hostedPolicyURL` so the link at the bottom appears.
//

import SwiftUI
import Combine
import UIKit

struct PrivacyPolicySheet: View {
    let language: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var isZH: Bool { language == "zh-Hans" }
    private var isDark: Bool { colorScheme == .dark }

    /// Public copy of this same text, submitted to App Store Connect as the
    /// "Privacy Policy URL". Leave nil until the page is actually published —
    /// a dead link is worse than no link, and reviewers do check.
    private var hostedPolicyURL: URL? {
        nil
    }

    private var pageBg: Color {
        isDark ? Color(hex: "161618") : Color(hex: "FAF7F2")
    }
    private var titleColor: Color {
        isDark ? .white : Color(hex: "2A2A2A")
    }
    private var bodyColor: Color {
        isDark ? Color(hex: "C8C2B8") : Color(hex: "4A4A4A")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if isZH { zhContent } else { enContent }
                }
                .padding(24)
            }
            .background(pageBg)
            .navigationBarTitle(
                Text(isZH ? "隐私政策" : "Privacy Policy"),
                displayMode: .inline
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isZH ? "完成" : "Done") { dismiss() }.foregroundColor(Design.accent)
                }
            }
        }
    }

    // MARK: - English

    private var enContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Last updated 21 October 2026")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(bodyColor.opacity(0.85))

            callout(
                "Reveal has no servers and no accounts. Your notes, favourites and preferences stay on your iPhone and are never sent to us.",
                "No analytics, no advertising, no tracking — and no data collected."
            )

            sectionTitle("1. Who we are")
            bodyText("Reveal is a daily Bible verse and reflection app published by Reveal Mashal. This policy explains what the app does with information and what control you keep. Write to revealmashal@gmail.com with any question about it.")

            sectionTitle("2. What is stored on your device")
            bodyText("Reveal is built around on-device storage. The following is written to the app's own sandbox on your iPhone and never leaves the device:")
            bullet("Reflection notes you write for a verse")
            bullet("Verse IDs you mark as favourites")
            bullet("Dates on which you opened a card, so the calendar can show your reading history")
            bullet("Language and appearance preferences")
            bullet("Whether the daily reminder is on, and at what time")
            bodyText("We cannot read, copy, back up, restore or disclose any of it, because it is never transmitted anywhere.")

            sectionTitle("3. How long it is kept")
            bodyText("Indefinitely, on your device only — until you remove it yourself. There is no server-side copy with a retention period, and nothing is queued for deletion on our side because nothing ever reaches us.")
            bullet("Deleting a note, or clearing its text, removes it immediately")
            bullet("Tapping the star again removes a favourite immediately")
            bullet("Deleting the app removes every note, favourite, date and setting at once")

            sectionTitle("4. What we do not collect")
            bodyText("Reveal does not collect, transmit or sell:")
            bullet("No name, email address, phone number or account of any kind")
            bullet("No advertising identifier (IDFA); App Tracking Transparency is not used because there is nothing to track")
            bullet("No cross-app or cross-site tracking, and no analytics, crash-reporting, advertising or attribution SDKs")
            bullet("No location, contacts, photos, camera or microphone")
            bullet("No health, fitness, financial or purchase information")

            sectionTitle("5. The only network requests the app makes")
            bodyText("Reading a full chapter: when you tap a verse reference, the app requests that chapter over HTTPS from a public Bible text API (bible.helloao.org). The request contains only a book code and chapter number — no personal data, no device identifier, no advertising identifier. We do not operate that service and cannot associate a request with you.")
            bodyText("Daily reminder: delivered through Apple's push notification service, only if you turn the reminder on, and used for nothing else.")
            bodyText("There are no other outbound requests. The app contains no third-party SDKs.")

            sectionTitle("6. Third parties")
            bodyText("We do not use a backend of our own and we do not share user data with anyone, so there is no third party that receives personal information from us. Where a third party is involved at all it is either the public Bible API above, which receives no personal data, or Apple, which handles notification delivery and any iCloud device backup you choose to enable under Apple's own privacy terms.")
            bodyText("Should we ever share user data with a third party, we would require that party to provide protection of that data equal to what this policy and Apple's guidelines require, and we would name it here before doing so.")

            sectionTitle("7. Permissions")
            bodyText("Notifications are the only permission the app can ask for, and only when you switch the daily reminder on. Declining it leaves every feature usable. You can withdraw it at any time in Settings → Daily Reminders, or in the iOS Settings app.")

            sectionTitle("8. Children's privacy")
            bodyText("Reveal is suitable for all ages. It has no accounts and transmits no personal information, so it does not knowingly collect personal information from children under 13 — or from anyone else.")

            sectionTitle("9. Your choices and rights")
            bodyText("Because the data never leaves your device, you hold it directly and can act without asking us:")
            bullet("Withdraw consent — turn the reminder off in Settings → Daily Reminders, or in the iOS Settings app")
            bullet("Delete a note or a favourite — clear it in the app, which takes effect immediately")
            bullet("Erase everything — delete the app from your device")
            bodyText("If you want help exercising a privacy right (access, correction, erasure, objection) or want us to confirm what we hold, email revealmashal@gmail.com. We hold no personal data, so in practice the answer will be that there is nothing on our side to export or erase — but we will answer.")

            sectionTitle("10. Security")
            bodyText("Notes and settings are protected by iOS file-level encryption at rest under your device passcode, inside the app sandbox that the system isolates from other apps. Nothing is transmitted to servers we operate, because we operate none.")

            sectionTitle("11. Changes to this policy")
            bodyText("If this policy changes, the date above changes and, where the change matters, it is described in the app's release notes. Continuing to use Reveal after an update means the current policy applies.")

            sectionTitle("12. Contact")
            bodyText("Reveal Mashal — revealmashal@gmail.com")

            Divider()
            linkToHostedPolicy()
        }
    }

    // MARK: - 简体中文

    private var zhContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("最后更新：2026 年 10 月 21 日")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(bodyColor.opacity(0.85))

            callout(
                "Reveal 没有服务器，也没有账号系统。你的笔记、收藏和偏好只保存在你自己的 iPhone 上，永远不会传输给我们。",
                "我们不使用分析、广告或追踪技术，也不收集任何数据。"
            )

            sectionTitle("1. 关于我们")
            bodyText("Reveal 是一款每日经文与灵修应用，由 Reveal Mashal 发布。本政策说明 App 如何处理信息，以及你保留哪些控制权。如有疑问，可发送邮件至 revealmashal@gmail.com。")

            sectionTitle("2. 保存在你设备上的内容")
            bodyText("Reveal 的核心设计是「数据留在本机」。以下内容只会写入 iPhone 上本 App 的沙盒，不会离开设备：")
            bullet("你为经文写下的反思笔记")
            bullet("你标记为收藏的经文")
            bullet("你打开过卡片的日期，让日历能显示你的阅读记录")
            bullet("语言与外观偏好")
            bullet("每日提醒的开关与时间")
            bodyText("我们无法查看、复制、备份、恢复或披露其中任何一项，因为这些内容从不被传输。")

            sectionTitle("3. 保存期限")
            bodyText("数据只保存在你的设备上，保存到你自行删除为止。我们这一侧没有服务器副本，因此不存在留存期限，也没有任何等待删除的数据。")
            bullet("清空笔记内容或删除笔记，立即生效")
            bullet("再次点击星标，收藏立即取消")
            bullet("删除 App，即一次清除全部笔记、收藏、日期与设置")

            sectionTitle("4. 我们不收集的信息")
            bodyText("Reveal 不会收集、传输或出售：")
            bullet("姓名、邮箱、手机号，或任何形式的用户账号")
            bullet("广告标识符（IDFA）；因为没有可追踪的对象，所以不使用 App Tracking Transparency")
            bullet("跨 App、跨网站追踪，也不集成分析、崩溃统计、广告或归因类 SDK")
            bullet("定位、通讯录、照片、相机、麦克风")
            bullet("健康、运动、财务或购买信息")

            sectionTitle("5. App 仅有的联网行为")
            bodyText("阅读全章：当你点击经文出处时，App 会通过 HTTPS 从一个公开的圣经文本 API（bible.helloao.org）获取该章内容。请求中只有书卷代码与章节号，不含任何个人数据、设备标识符或广告标识符。该服务并非由我们运营，我们也无法把某次请求与你对应起来。")
            bodyText("每日提醒：仅在你开启后，通过 Apple 的推送通知服务发送，不用于其他任何用途。")
            bodyText("除此以外没有其他对外请求。App 不包含任何第三方 SDK。")

            sectionTitle("6. 第三方")
            bodyText("我们没有自建后端，也不与任何方共享用户数据，因此不存在从我们这里获得个人信息的第三方。唯一涉及的外部服务是上面提到的公开圣经 API（不接收个人数据），以及 Apple（负责通知投递，以及你自行启用的 iCloud 设备备份，按 Apple 自身的隐私条款处理）。")
            bodyText("若未来确需与第三方共享用户数据，我们会要求该方提供与本政策及 Apple 准则同等水平的保护，并在共享之前于此处明示该方身份。")

            sectionTitle("7. 权限")
            bodyText("通知是 App 唯一可能申请的权限，且只在你开启每日提醒时才申请。拒绝后所有功能依然可用。你随时可以在 设置 → 每日提醒 中撤回，或在 iOS 系统设置中关闭。")

            sectionTitle("8. 儿童隐私")
            bodyText("Reveal 适合所有年龄段使用。App 没有账号，也不传输任何个人信息，因此不会有意收集 13 岁以下儿童的个人信息，也不会收集任何人的个人信息。")

            sectionTitle("9. 你的选择与权利")
            bodyText("数据从不离开你的设备，因此你可以直接处置，无需先征得我们同意：")
            bullet("撤回同意 —— 在 设置 → 每日提醒 中关闭，或在 iOS 系统设置中关闭通知")
            bullet("删除笔记或收藏 —— 在 App 内清除，立即生效")
            bullet("彻底清除 —— 从设备删除本 App")
            bodyText("如需协助行使隐私权利（查阅、更正、删除、反对），或希望我们确认持有何种数据，请发送邮件至 revealmashal@gmail.com。我们不持有任何个人数据，所以实际上没有可导出或可删除的内容——但我们一定会回复。")

            sectionTitle("10. 安全")
            bodyText("笔记与设置由 iOS 的文件级加密保护（依托你的设备密码），并处于系统隔离的 App 沙盒内。没有任何数据被传输到我们运营的服务器，因为我们没有服务器。")

            sectionTitle("11. 政策变更")
            bodyText("若本政策变更，会更新上方的日期；若变更重要，会在 App 的更新说明中注明。更新后继续使用 Reveal，即表示适用当前版本的政策。")

            sectionTitle("12. 联系我们")
            bodyText("Reveal Mashal — revealmashal@gmail.com")

            Divider()
            linkToHostedPolicy()
        }
    }

    // MARK: - Building blocks

    private func callout(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(titleColor)
            Text(subtitle).font(.system(size: 13)).foregroundColor(bodyColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Design.accent.opacity(0.12))
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 15, weight: .bold)).foregroundColor(titleColor).padding(.top, 8)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text).font(.system(size: 14)).foregroundColor(bodyColor).lineSpacing(4)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").font(.system(size: 14)).foregroundColor(Design.accent)
            Text(text).font(.system(size: 14)).foregroundColor(bodyColor).lineSpacing(4)
        }
    }

    @ViewBuilder
    private func linkToHostedPolicy() -> some View {
        if let hostedPolicyURL {
            Link(destination: hostedPolicyURL) {
                HStack(spacing: 8) {
                    Image(systemName: "safari.fill").foregroundColor(Design.accent)
                    Text(isZH ? "查看网页版隐私政策" : "View this policy on the web")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Design.accent)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Design.accent.opacity(0.6))
                }
            }
        }
    }
}
