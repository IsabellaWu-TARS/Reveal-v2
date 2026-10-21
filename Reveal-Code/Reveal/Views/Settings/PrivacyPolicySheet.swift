//
//  PrivacyPolicySheet.swift
//  Reveal
//
//  In-app privacy policy.
//
//  Why this exists: App Store Review Guideline 5.1.1 only requires a
//  public privacy-policy URL, but a reviewer looking at an app that stores
//  personal reflections will reasonably expect to find an explanation
//  *inside* the app. This sheet is that explanation, and it also links
//  out to the hosted version of the same text.
//
//  The wording here is deliberately kept in sync with `Privacy/privacy.html`
//  and with the App Privacy answers in App Store Connect:
//
//    Data Collected ......... User Content (Other User Content)
//    Data Not Collected ..... Identifiers, Usage Data, Diagnostics,
//                             Tracking, Location, Purchases, etc.
//    Tracking ............... None (no ATT prompt is shown, correctly)
//    Third-party SDKs ....... None
//    Servers ................ None
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

    /// The hosted copy that is submitted to App Store Connect as the
    /// "Privacy Policy URL". Update this when you publish the page.
    private var policyURL: URL? {
        URL(string: "https://revealmashal.com/privacy")
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
                VStack(alignment: .leading, spacing: 20) {
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
        VStack(alignment: .leading, spacing: 20) {
            callout(
                "Reveal has no servers and no accounts. Your notes, favourites and preferences are stored only on your iPhone and are never transmitted to us.",
                "We do not use analytics, advertising or tracking of any kind."
            )

            sectionTitle("1. Data stored on your device")
            bodyText("Reveal is built around on-device storage. The following is written to your iPhone's app sandbox and never leaves the device:")
            bullet("Your reflection notes written for a verse")
            bullet("Verse IDs you mark as favourites")
            bullet("Dates on which you opened a card")
            bullet("Language and appearance preferences")
            bullet("Daily reminder on/off and reminder time")
            bodyText("Because this data lives only on your device, we cannot see it, back it up, restore it, or hand it to anyone. Deleting the app deletes this data.")

            sectionTitle("2. Data we do not collect")
            bodyText("Reveal does not collect, transmit or sell:")
            bullet("No name, email address, phone number, or user account of any kind")
            bullet("No advertising identifier (IDFA) and no identifier-for-advertising tracking")
            bullet("No cross-app or cross-site tracking")
            bullet("No analytics, crash-reporting, advertising or attribution SDKs")
            bullet("No location, contacts, photos, camera or microphone")
            bullet("No health, fitness, financial or purchase information")

            sectionTitle("3. Network requests")
            bodyText("When you tap a verse reference to read the full chapter, the app fetches that chapter over HTTPS from a public Bible text API (bible.helloao.org). This request contains no personal data and no device identifier — only the requested book and chapter.")
            bodyText("Apple's Push Notification service is used solely to deliver the daily reminder, and only if you turn it on.")

            sectionTitle("4. Permissions")
            bullet("Notifications — to deliver the optional daily verse reminder at the time you chose. Not required; you can use every feature without it.")

            sectionTitle("5. Children's privacy")
            bodyText("Reveal is suitable for all ages and does not knowingly collect personal information from children under 13. The app has no accounts and transmits no personal data.")

            sectionTitle("6. Your rights and controls")
            bodyText("You are always in control of your data:")
            bullet("Delete a note — clear the text in the note editor, or delete the app")
            bullet("Delete a favourite — tap the star again, or delete the app")
            bullet("Delete everything — delete the app from your device")
            bullet("Stop the reminder — turn off Daily Reminders in Settings")

            sectionTitle("7. Security")
            bodyText("Reveal uses iOS platform encryption for data at rest and Apple's standard sandbox protections. Data is never transmitted to servers operated by us.")

            sectionTitle("8. Changes to this policy")
            bodyText("If this policy changes, the date above is updated and, where significant, the change is described in the app's release notes.")

            sectionTitle("9. Contact us")
            bodyText("Questions about privacy can be sent to revealmashal@gmail.com.")

            Divider()
            linkToWebPolicy()
        }
    }

    // MARK: - 简体中文

    private var zhContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            callout(
                "Reveal 没有服务器，也没有账号系统。你的笔记、收藏和偏好设置只保存在你自己的 iPhone 上，永远不会传输给我们。",
                "我们不使用任何分析、广告或追踪技术。"
            )

            sectionTitle("1. 保存在你设备上的数据")
            bodyText("Reveal 的核心设计原则是「数据留在本机」。以下内容会写入你 iPhone 的 App 沙盒，不会离开设备：")
            bullet("你为每节经文写下的反思笔记")
            bullet("你标记为收藏的经文")
            bullet("你打开过卡片的日期")
            bullet("语言与外观偏好")
            bullet("每日提醒的开关与时间")
            bodyText("由于这些数据只存在于你的设备上，我们无法查看、备份、恢复或交予第三方。删除 App 即等同于删除这些数据。")

            sectionTitle("2. 我们不收集的数据")
            bodyText("Reveal 不会收集、传输或出售以下任何信息：")
            bullet("没有姓名、邮箱、手机号，也没有任何形式的用户账号")
            bullet("不读取也不使用广告标识符（IDFA），不进行广告追踪")
            bullet("不进行跨 App、跨网站追踪")
            bullet("不集成分析、崩溃统计、广告或归因类 SDK")
            bullet("不获取定位、通讯录、照片、相机、麦克风")
            bullet("不获取健康、运动、财务或购买信息")

            sectionTitle("3. 联网行为")
            bodyText("当你点击经文出处以阅读全章时，App 会通过 HTTPS 从一个公开的圣经文本 API（bible.helloao.org）获取该章内容。此请求不包含任何个人数据或设备标识符，只有被请求的书名与章节号。")
            bodyText("Apple 的推送通知服务仅用于发送每日提醒，且仅在你开启后启用。")

            sectionTitle("4. 权限使用")
            bullet("通知 —— 在你设定的时间发送可选的每日经文提醒。非必需权限，拒绝后所有功能依然可用。")

            sectionTitle("5. 儿童隐私")
            bodyText("Reveal 适合所有年龄段使用，且本 App 不会有意收集 13 岁以下儿童的个人信息。本 App 没有账号，也不传输任何个人数据。")

            sectionTitle("6. 你的权利与控制")
            bodyText("你始终掌握自己的数据：")
            bullet("删除笔记 —— 在笔记编辑器中清空文字，或删除 App")
            bullet("取消收藏 —— 再次点击星标，或删除 App")
            bullet("删除全部数据 —— 从设备删除本 App")
            bullet("关闭提醒 —— 在设置中关闭每日提醒")

            sectionTitle("7. 安全")
            bodyText("Reveal 使用 iOS 平台的静态加密机制保护本地数据，并依赖 Apple 对 App 沙盒的标准保护。数据从不传输至我们运营的服务器。")

            sectionTitle("8. 政策变更")
            bodyText("若本政策变更，会更新上方的日期；若有重大变更，会在 App 的更新说明中说明。")

            sectionTitle("9. 联系我们")
            bodyText("如对隐私有任何疑问，可发送邮件至 revealmashal@gmail.com。")

            Divider()
            linkToWebPolicy()
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
    private func linkToWebPolicy() -> some View {
        if let policyURL {
            Link(destination: policyURL) {
                HStack(spacing: 8) {
                    Image(systemName: "safari.fill").foregroundColor(Design.accent)
                    Text(isZH ? "查看完整版隐私政策" : "View the full policy online")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Design.accent)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Design.accent.opacity(0.6))
                }
            }
        }
    }
}
