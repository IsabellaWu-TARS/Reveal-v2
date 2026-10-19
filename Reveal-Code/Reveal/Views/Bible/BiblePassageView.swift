//
//  BiblePassageView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct BiblePassageView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore

    // P10 removed the Bible API call and showed only the bundled card text.
    // P16 puts a real API back for the part the card cannot carry: the whole
    // chapter, so the verse can be read in context.
    //
    // What you see on this screen:
    //   • Reference (e.g. "Genesis 1:1, WEB")
    //   • Verse text (Georgia serif, paper-cream surface) — straight from the
    //     bundled JSON, so it renders instantly and works offline
    //   • Reflection question
    //   • Action prompt
    //   • The full chapter, fetched from bible.helloao.org
    //     (eng_web / cmn_cu1) with the card's verse highlighted.
    //
    // The local card is the offline floor: if the fetch fails the verse is
    // still on screen, with a retry for the chapter below it.

    @State private var chapter: BibleChapter?
    @State private var isLoadingChapter = false
    @State private var chapterError: String?

    private var isZH: Bool { dailyCardStore.appLanguage == "zh-Hans" }

    /// Reloads when the date rolls over or the language changes.
    private var chapterKey: String {
        guard let card = dailyCardStore.currentCard else { return "none" }
        return "\(card.id)|\(dailyCardStore.appLanguage)"
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    BackCircleButton { withAnimation { currentPage = .home } }
                    Spacer()
                    Text(dailyCardStore.appLanguage == "zh-Hans" ? "经文" : "Full Passage")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Color.clear.frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                }
                .padding(.horizontal, Design.horizontalPadding)
                .padding(.top, 16)

                ScrollViewReader { proxy in
                ScrollView {
                    if let card = dailyCardStore.currentCard {
                        VStack(alignment: .leading, spacing: 16) {
                            // Reference header (e.g. "Genesis 1:1, WEB")
                            Text(card.referenceWithTranslation(language: dailyCardStore.appLanguage))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Design.paperInk)

                            // Verse body — pulled directly from the local
                            // bilingual JSON (no network, no spinner).
                            Text(card.verseText(language: dailyCardStore.appLanguage))
                                .font(.custom("Georgia", size: 19))
                                .foregroundColor(Design.paperInkDeep)
                                .lineSpacing(10)
                                .textSelection(.enabled)

                            Divider().padding(.vertical, 8)

                            // Reflection question
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Design.accent)
                                Text(card.questionText(language: dailyCardStore.appLanguage))
                                    .font(.custom("Georgia", size: 15))
                                    .foregroundColor(Design.paperInk)
                                    .lineSpacing(6)
                            }

                            Spacer().frame(height: 8)

                            // Action prompt
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Design.accent)
                                Text(card.actionText(language: dailyCardStore.appLanguage))
                                    .font(.custom("Georgia", size: 15))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Design.accent)
                                    .lineSpacing(6)
                            }

                            chapterSection(card)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // No card available — fall back to a soft hint rather
                        // than an empty screen.
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(Design.accent.opacity(0.5))
                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "暂无经文" : "No passage available")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Design.paperInkHint)
                        }
                        .padding(.top, 80)
                    }
                }
                .background(RoundedRectangle(cornerRadius: Design.cardRadius).fill(Design.paperCardSurface).shadow(color: Design.cardShadowColor, radius: 16, x: 0, y: 8))
                .overlay(alignment: .bottom) {
                    // Text scrolls under the card's bottom edge; fade it into
                    // the paper colour instead of slicing a line in half.
                    LinearGradient(
                        colors: [Design.paperCardSurface.opacity(0), Design.paperCardSurface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 26)
                    .allowsHitTesting(false)
                    .clipShape(UnevenRoundedRectangle(
                        bottomLeadingRadius: Design.cardRadius,
                        bottomTrailingRadius: Design.cardRadius
                    ))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .task(id: chapterKey) { await loadChapter() }
                // Land on the card's verse instead of the top of the chapter.
                .onChange(of: chapter) { _, fetched in
                    guard let fetched, let card = dailyCardStore.currentCard else { return }
                    guard fetched.verse(card.verse) != nil else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(Design.springAnim) {
                            proxy.scrollTo("verse-\(card.verse)", anchor: .center)
                        }
                    }
                }
                }

                BackToHomeButton { withAnimation { currentPage = .home } }
                    .padding(.horizontal, Design.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Full chapter

    @MainActor
    private func loadChapter() async {
        guard let card = dailyCardStore.currentCard else { return }
        let requestedKey = chapterKey
        chapter = nil
        chapterError = nil
        isLoadingChapter = true
        defer { isLoadingChapter = false }
        do {
            let fetched = try await BibleAPIService.shared.chapter(
                book: card.book,
                chapter: card.chapter,
                language: dailyCardStore.appLanguage
            )
            // A response for a card/language we no longer show must not land.
            guard chapterKey == requestedKey else { return }
            chapter = fetched
            chapterError = nil
        } catch {
            guard chapterKey == requestedKey else { return }
            chapterError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @ViewBuilder
    private func chapterSection(_ card: RevealCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().padding(.top, 6)

            HStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Design.accent)
                Text(isZH ? "整章经文" : "Full Chapter")
                    .font(.custom("Georgia", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Design.paperInkDeep)
                Spacer()
                if let chapter {
                    Text(isZH ? "\(chapter.verses.count) 节" : "\(chapter.verses.count) verses")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Design.paperInkHint)
                }
            }

            if let chapter {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(chapter.verses) { verse in
                        verseRow(verse, highlighted: verse.number == card.verse)
                            .id("verse-\(verse.number)")
                    }
                }
                .padding(.top, 2)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("chapterVerses")

                Text("\(chapter.bookName) \(chapter.chapterNumber) · " + (isZH ? "新标点和合本" : "World English Bible"))
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Design.paperInkHint)
                    .padding(.top, 8)
            } else if isLoadingChapter {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small).tint(Design.accent)
                    Text(isZH ? "正在加载整章…" : "Loading chapter…")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(Design.paperInkMuted)
                }
                .padding(.vertical, 14)
            } else if let chapterError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isZH ? "无法加载整章经文，今日经文仍可离线阅读。" : "Couldn't load the full chapter — today's verse still reads offline.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Design.paperInkMuted)
                        .lineSpacing(4)
                    Text(chapterError)
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(Design.paperInkHint)
                    Button {
                        Task { await loadChapter() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text(isZH ? "重试" : "Retry")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Design.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Design.accent.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private func verseRow(_ verse: BibleVerse, highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let heading = verse.heading, !heading.isEmpty {
                Text(heading)
                    .font(.custom("Georgia", size: 12))
                    .italic()
                    .foregroundColor(Design.paperInkHint)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(verse.number)")
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(highlighted ? Design.accent : Design.paperInkHint)
                    .frame(width: 20, alignment: .trailing)
                Text(verse.text)
                    .font(.custom("Georgia", size: highlighted ? 17 : 15))
                    .foregroundColor(highlighted ? Design.paperInkDeep : Design.paperInkMuted)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(highlighted ? Design.accent.opacity(0.14) : Color.clear)
            )
        }
    }
}
