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
    private var isZH: Bool { language == "zh-Hans" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isZH { zhContent } else { enContent }
                }
                .padding(24)
            }
            .background(Color(hex: "FAF7F2"))
            .navigationTitle(isZH ? "资料来源与版权声明" : "Sources & Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Design.accent)
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
            bodyText("Chinese Scripture quotations are taken from the Open Translation Bible (Chinese Edition).")
            bodyText("Copyright © Open Translation Bible Contributors.")
            bodyText("Licensed under the Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0).")
            linkText("Source: https://github.com/OpenTranslationBible/open-bible")
            linkText("License: https://creativecommons.org/licenses/by-sa/4.0/")
            Divider()
            sectionTitle("Attribution")
            bodyText("This application includes Bible text from the World English Bible (Public Domain) and the Open Translation Bible (CC BY-SA 4.0).")
            sectionTitle("Original Content")
            bodyText("All devotionals, reflections, study questions, user interface designs, graphics, logos, and other original content are created by Reveal and are not part of the Bible translations cited above.")
            sectionTitle("Copyright")
            bodyText("World English Bible (WEB): Public Domain.")
            bodyText("Open Translation Bible: Licensed under CC BY-SA 4.0.")
            bodyText("© Reveal. All original app content reserved by their respective owners.")
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
            bodyText("本应用所引用的中文圣经经文，部分摘录自 Open Translation Bible（开放翻译圣经）中文版。")
            bodyText("版权 © Open Translation Bible Contributors")
            bodyText("采用 Creative Commons Attribution-ShareAlike 4.0 International（CC BY-SA 4.0）许可协议发布。")
            bodyText("根据该许可协议，使用者可以分享及改编相关内容，但须注明出处，并以相同许可协议发布衍生作品。")
            linkText("来源：https://github.com/OpenTranslationBible/open-bible")
            linkText("许可协议：https://creativecommons.org/licenses/by-sa/4.0/")
            Divider()
            sectionTitle("版权归属")
            bodyText("本应用包含来自以下译本的圣经内容：")
            bodyText("• World English Bible（WEB）— 公有领域（Public Domain）")
            bodyText("• Open Translation Bible 中文版 — CC BY-SA 4.0")
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
            bodyText("Open Translation Bible：CC BY-SA 4.0")
            bodyText("© Reveal. 应用原创内容版权所有。")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "2A2A2A")).padding(.top, 8)
    }
    private func bodyText(_ text: String) -> some View {
        Text(text).font(.system(size: 14)).foregroundColor(Color(hex: "4A4A4A")).lineSpacing(4)
    }
    private func linkText(_ text: String) -> some View {
        Text(text).font(.system(size: 13)).foregroundColor(Design.accent)
    }
}
