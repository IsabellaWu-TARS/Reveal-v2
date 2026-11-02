//
//  AboutBibleSourcesSheet.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct AboutBibleSourcesSheet: View {
    let language: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var isZH: Bool { language == "zh-Hans" }
    private var isDark: Bool { colorScheme == .dark }

    private var pageBg: Color {
        isDark ? Color(hex: "161618") : Color(hex: "FAF7F2")
    }
    private var titleColor: Color {
        isDark ? Color.white : Color(hex: "2A2A2A")
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
                Text(isZH ? "资料来源与版权声明" : "Sources & Licenses"),
                displayMode: .inline
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isZH ? "完成" : "Done") { dismiss() }.foregroundColor(Design.accent)
                }
            }
        }
    }

    private var enContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("English Bible Text")
            bodyText("Scripture quotations marked \"WEB\" are taken from the World English Bible (WEB).")
            bodyText("The World English Bible is a Public Domain translation of the Holy Bible and may be freely used, copied, and distributed.")
            linkText("Source: https://worldenglish.bible")
            Divider()
            sectionTitle("Chinese Bible Text")
            bodyText("Chinese Scripture quotations are taken from the Chinese Union Version of 1919 — the 官話和合本, \"God\" edition. The complete text ships with the app and is read offline.")
            bodyText("The 1919 text is in the Public Domain: its copyright has expired. The 1989 new-punctuation revision, whose rights are administered by the United Bible Societies and the Hong Kong Bible Society, is not used anywhere in this app.")
            linkText("Reference: https://zh.wikisource.org/wiki/聖經_(和合本)")
            Divider()
            sectionTitle("Attribution")
            bodyText("This application includes Bible text from the World English Bible (Public Domain) and the Chinese Union Version, 1919 edition (Public Domain).")
            sectionTitle("Original Content")
            bodyText("All devotionals, reflections, study questions, user interface designs, graphics, logos, and other original content are created by Reveal and are not part of the Bible translations cited above.")
            sectionTitle("Copyright")
            bodyText("World English Bible (WEB): Public Domain.")
            bodyText("Chinese Union Version (CUV, 1919): Public Domain.")
            bodyText("© Reveal. All original app content reserved by their respective owners.")
            Divider()
            sectionTitle("Privacy Policy")
            bodyText("Reveal has no servers and no accounts. The personal data the app stores — your reflection notes, favourites, viewing history, language preference, and reminder settings — are stored only on your device and are never transmitted to Reveal.")
            bodyText("We do not use analytics, advertising, cross-app tracking or any third-party SDKs. Notifications are optional and used only to deliver the daily reminder you choose.")
            bodyText("The only network request the app makes is for an English chapter: when you tap to read it, the chapter is fetched from a public Bible text API. The request contains no personal data or device identifier. Chinese chapters are bundled with the app and read entirely offline.")
            bodyText("The full policy is available in Settings → Privacy Policy, and at the privacy policy URL in this app's App Store listing.")
            bodyText("Privacy questions: revealmashal@gmail.com")
        }
    }

    private var zhContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("英文圣经")
            bodyText("本应用所引用的英文圣经经文，部分摘录自 World English Bible（WEB）。")
            bodyText("World English Bible（WEB）为公有领域（Public Domain）译本，可自由使用、复制、修改及传播，无需额外授权。")
            linkText("来源：https://worldenglish.bible")
            Divider()
            sectionTitle("中文圣经")
            bodyText("本应用引用的中文经文，取自 1919 年《和合本》（官話和合本「神」版）。全本经文随 App 一起打包，离线阅读，不联网。")
            bodyText("1919 年版已进入公有领域。本应用不使用 1989 年「新标点」版——该版本的权利由联合圣经公会与香港圣经公会主张。")
            linkText("来源：https://zh.wikisource.org/wiki/聖經_(和合本)")
            Divider()
            sectionTitle("版权归属")
            bodyText("本应用包含来自以下译本的圣经内容：")
            bodyText("• World English Bible（WEB）— 公有领域（Public Domain）")
            bodyText("• 中文和合本（1919）— 公有领域")
            bodyText("相关版权及许可归原版权所有者及贡献者所有。")
            Divider()
            sectionTitle("原创内容")
            bodyText("本应用中的灵修内容、反思问题、学习笔记、界面设计、图标、标识、插图及其他原创内容，均由 Reveal 团队制作或依法使用，不属于上述圣经译本内容。")
            Divider()
            sectionTitle("免责声明")
            bodyText("本应用旨在提供圣经阅读、学习与灵修辅助服务。圣经经文版权归其各自译本及授权方所有。")
            bodyText("如发现版权归属或引用信息有误，请联系我们进行更正。")
            Divider()
            sectionTitle("版权所有")
            bodyText("World English Bible（WEB）：Public Domain")
            bodyText("中文和合本（1919）：公有领域")
            bodyText("© Reveal. 应用原创内容版权所有。")
            Divider()
            sectionTitle("隐私政策")
            bodyText("Reveal 没有服务器，也没有账号系统。App 内保存的个人数据——你的反思笔记、收藏的经文、阅读记录、语言偏好与提醒设置——只保存在你的设备上，永远不会传输给 Reveal。")
            bodyText("我们不使用分析、广告、跨 App 追踪或任何第三方 SDK。通知权限为可选功能，仅在你启用后用于发送每日提醒。")
            bodyText("App 唯一的联网行为是当你以英文查看全章时，向一个公开的圣经文本 API 请求经文，该请求不包含任何个人数据或设备标识符。中文经文已内置在 App 内，读取时完全不联网。")
            bodyText("本政策同款文本已在网页上发布，最新版本可在 App Store 资料页提供的链接查看。")
            bodyText("如有隐私相关疑问，请联系：revealmashal@gmail.com")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 15, weight: .bold)).foregroundColor(titleColor).padding(.top, 8)
    }
    private func bodyText(_ text: String) -> some View {
        Text(text).font(.system(size: 14)).foregroundColor(bodyColor).lineSpacing(4)
    }
    private func linkText(_ text: String) -> some View {
        Text(text).font(.system(size: 13)).foregroundColor(Design.accent)
    }
}
