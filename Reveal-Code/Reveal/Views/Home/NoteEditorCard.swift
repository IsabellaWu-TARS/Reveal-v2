//
//  NoteEditorCard.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct NoteEditorCard: View {
    @Binding var noteText: String
    let card: RevealCard
    let language: String
    let onClose: () -> Void
    @FocusState private var isFocused: Bool
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    private var titleText: String { language == "zh-Hans" ? "我的感想" : "My Reflection" }
    private var hintText: String { language == "zh-Hans" ? "写下你的反思..." : "Write your reflection..." }
    private var autoSaveText: String { language == "zh-Hans" ? "自动保存" : "Auto-saves" }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = language == "zh-Hans" ? "yyyy年M月d日" : "MMMM d, yyyy"
        return f.string(from: Date())
    }

    private var cardBg: Color {
        isDark ? Color(hex: "1F1E1B") : Color(hex: "FAF7F2")
    }
    private var editorBg: Color {
        isDark ? Color(hex: "15140F") : Color(hex: "F5F2ED")
    }
    private var titleColor: Color {
        isDark ? Color.white : Color(hex: "2A2A2A")
    }
    private var textColor: Color {
        isDark ? Color(hex: "E8E5DE") : Color(hex: "2A2A2A")
    }
    private var hintTextColor: Color {
        isDark ? Color(hex: "6E6B66") : Color(hex: "BFBFBF")
    }
    private var mutedTextColor: Color {
        isDark ? Color(hex: "8A857E") : Color(hex: "9E9E9E")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(titleText).font(.system(size: 18, weight: .bold)).foregroundColor(titleColor)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(mutedTextColor)
                }
            }

            Divider().padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.referenceText(language: language)).font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent)
                Text(formattedDate).font(.system(size: 11, weight: .light)).foregroundColor(mutedTextColor)
            }
            .padding(.bottom, 12)

            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text(hintText).font(.system(size: 15)).foregroundColor(hintTextColor).padding(.horizontal, 4).padding(.vertical, 8)
                }
                TextEditor(text: $noteText)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .onChange(of: noteText) { _, _ in
                        NotesStore.shared.save()
                    }
            }
            // P12: minHeight dropped from 160 → 100 so the overall card reads
            // as smaller. Combined with the call-site maxHeight cap, the
            // editor gracefully shrinks when the keyboard appears instead of
            // clipping off-screen.
            // P17: the TextEditor's ideal width is unbounded, so the whole
            // card used to grow past the screen edge; pin it to the card.
            .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 220, alignment: .topLeading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16).fill(editorBg).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(isDark ? 0.4 : 0.06), lineWidth: 1)))

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle").font(.system(size: 11))
                Text(autoSaveText).font(.system(size: 11, weight: .light))
            }
            .foregroundColor(Design.accent)
            .padding(.top, 8)
        }
        // P12: outer padding 20 → 16 for a more compact card.
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Design.notesRadius).fill(cardBg).shadow(color: Color.black.opacity(isDark ? 0.5 : 0.12), radius: 20, x: 0, y: 10))
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true } }
        .onDisappear { isFocused = false }
    }
}
