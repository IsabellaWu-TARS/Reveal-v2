//
//  ShareOptionsCard.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct ShareOptionsCard: View {
    let card: RevealCard
    let language: String
    let noteText: String
    let onSelect: (ShareManager.ShareMode) -> Void
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    private var cardBg: Color {
        isDark ? Color(hex: "1F1E1B") : Color(hex: "FAF7F2")
    }
    private var titleColor: Color {
        isDark ? Color.white : Color(hex: "2A2A2A")
    }
    private var subtitleColor: Color {
        isDark ? Color(hex: "8A857E") : Color(hex: "9E9E9E")
    }
    private var chevronColor: Color {
        isDark ? Color(hex: "5A5750") : Color(hex: "D0D0D0")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language == "zh-Hans" ? "分享" : "Share")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(titleColor)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(subtitleColor)
                }
            }
            .padding(20)

            Divider()

            VStack(spacing: 4) {
                ForEach(ShareManager.ShareMode.allCases, id: \.self) { mode in
                    Button(action: {
                        HapticManager.light()
                        onSelect(mode)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: mode.iconName).font(.system(size: 20)).foregroundColor(Design.accent)
                                .frame(width: 36, height: 36)
                                .background(Design.accent.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(language == "zh-Hans" ? mode.titleZH(lang: language) : mode.titleEN(lang: language))
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(titleColor)
                                Text(language == "zh-Hans" ? mode.subtitleZH() : mode.subtitleEN())
                                    .font(.system(size: 12, weight: .light)).foregroundColor(subtitleColor)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(chevronColor)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(RoundedRectangle(cornerRadius: Design.notesRadius).fill(cardBg).shadow(color: Color.black.opacity(isDark ? 0.5 : 0.15), radius: 20, x: 0, y: 10))
    }
}
