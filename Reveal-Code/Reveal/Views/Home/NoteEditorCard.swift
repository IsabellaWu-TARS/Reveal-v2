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

    private var titleText: String { language == "zh-Hans" ? "我的感想" : "My Reflection" }
    private var hintText: String { language == "zh-Hans" ? "写下你的反思..." : "Write your reflection..." }
    private var autoSaveText: String { language == "zh-Hans" ? "自动保存" : "Auto-saves" }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = language == "zh-Hans" ? "yyyy年M月d日" : "MMMM d, yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(titleText).font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "2A2A2A"))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "9E9E9E"))
                }
            }

            Divider().padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.referenceText(language: language)).font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent)
                Text(formattedDate).font(.system(size: 11, weight: .light)).foregroundColor(Color(hex: "9E9E9E"))
            }
            .padding(.bottom, 12)

            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text(hintText).font(.system(size: 15)).foregroundColor(Color(hex: "BFBFBF")).padding(.horizontal, 4).padding(.vertical, 8)
                }
                TextEditor(text: $noteText)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "2A2A2A"))
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
            .frame(minHeight: 100)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "F5F2ED")).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1)))

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle").font(.system(size: 11))
                Text(autoSaveText).font(.system(size: 11, weight: .light))
            }
            .foregroundColor(Design.accent)
            .padding(.top, 8)
        }
        // P12: outer padding 20 → 16 for a more compact card.
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Design.notesRadius).fill(Color(hex: "FAF7F2")).shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10))
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true } }
        .onDisappear { isFocused = false }
    }
}
