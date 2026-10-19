//
//  CalendarView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct CalendarView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @State private var displayedMonth: Date = Date()
    @State private var selectedSection: CalendarSection = .daily

    enum CalendarSection: String, CaseIterable {
        case daily = "Daily", favorites = "Favorites", notes = "Notes"
        func titleZH(lang: String) -> String {
            switch self {
            case .daily: return "每日"
            case .favorites: return "收藏"
            case .notes: return "笔记"
            }
        }
        func titleEN(lang: String) -> String { rawValue }
    }

    private let calendar = Calendar.current

    // BUG FIX (P2-2): Previously this was a static `let` initialised once,
    // so Chinese users always saw English weekday letters even after
    // switching language. Now we read the store's current language live.
    private var weekdays: [String] {
        dailyCardStore.appLanguage == "zh-Hans"
            ? ["日", "一", "二", "三", "四", "五", "六"]
            : ["S", "M", "T", "W", "T", "F", "S"]
    }

    private var pageTitle: String {
        dailyCardStore.appLanguage == "zh-Hans" ? "经文历史" : "Scripture History"
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = dailyCardStore.appLanguage == "zh-Hans" ? "yyyy 年 M 月" : "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: first) { days.append(date) }
        }
        return days
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                HStack {
                    // BUG FIX (P6): wrapping the assignment in `withAnimation`
                    // on top of the parent `.animation(... value: currentPage)`
                    // created a double-animation that, combined with the heavy
                    // background modifier on the section tabs, could trap the
                    // runloop — taps stopped registering. Now we just mutate
                    // the binding and let the parent animation handle the rest.
                    BackCircleButton { currentPage = .home }
                    Spacer()
                    Text(pageTitle)
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                    Spacer()
                    Color.clear.frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                }
                .padding(.horizontal, Design.horizontalPadding)
                .padding(.top, 16)

                sectionTabs
                    .padding(.horizontal, Design.horizontalPadding)
                    .padding(.top, 16)

                switch selectedSection {
                case .daily: dailySection
                case .favorites: favoritesSection
                case .notes: notesSection
                }
            }
        }
        // BUG FIX (P6): reset the selected tab every time the user opens
        // Calendar, so they always start on "Daily" instead of landing on
        // whatever sub-tab they last visited (Favorites / Notes).
        .onAppear { selectedSection = .daily }
    }

    private var sectionTabs: some View {
        // BUG FIX (P6): simplified — removed `Spacer()` and the multi-layer
        // Capsule background overlay that could lock the runloop when the
        // selected/unselected state toggled.
        HStack(spacing: 8) {
            ForEach(CalendarSection.allCases, id: \.self) { section in
                let isSelected = (selectedSection == section)
                Button(action: { selectedSection = section }) {
                    Text(dailyCardStore.appLanguage == "zh-Hans" ? section.titleZH(lang: "zh-Hans") : section.titleEN(lang: "en"))
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : Design.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Design.accent : Color.white.opacity(0.6))
                                .overlay(
                                    Capsule().stroke(Design.accent.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dailySection: some View {
        // BUG FIX (P5): previously the calendar grid was the only thing in
        // the VStack and on small iPhones (13 mini, SE) it pushed past the
        // safe area. Now the entire daily section lives inside a ScrollView
        // so the user can always reach every day, and on Pro Max nothing is
        // cut off at the bottom.
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button(action: { withAnimation { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth } }) {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(Design.accent).frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                    }
                    Spacer()
                    Text(monthTitle).font(.system(size: 17, weight: .semibold)).foregroundColor(.primary)
                    Spacer()
                    Button(action: { withAnimation { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth } }) {
                        Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundColor(Design.accent).frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
                    }
                }
                .padding(.horizontal, 8)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Design.calendarGridSpacing), count: 7), spacing: Design.calendarGridSpacing) {
                    ForEach(weekdays, id: \.self) { w in
                        Text(w).font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent.opacity(0.7))
                    }
                    ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                        CalendarDayCell(date: date)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "FAF7F2")).shadow(color: Design.cardShadowColor, radius: 12))
            }
            .padding(.horizontal, Design.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var favoritesSection: some View {
        ScrollView {
            if dailyCardStore.favoriteIds.isEmpty {
                emptyState(
                    icon: "star",
                    title: dailyCardStore.appLanguage == "zh-Hans" ? "暂无收藏" : "No Favorites Yet",
                    subtitle: dailyCardStore.appLanguage == "zh-Hans" ? "点击卡片上的星星来收藏" : "Tap the star on any card to save it here"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dailyCardStore.allCards.filter { dailyCardStore.favoriteIds.contains($0.id) }) { card in
                        FavoriteCardRow(card: card, language: dailyCardStore.appLanguage)
                    }
                }
                .padding(.horizontal, Design.horizontalPadding).padding(.top, 16).padding(.bottom, 40)
            }
        }
    }

    private var notesSection: some View {
        ScrollView {
            // BUG FIX (P1-3): Show ALL notes (per card id), not just the
            // legacy single-slot UserNoteText which was overwritten between
            // cards.
            let allNotes = NotesStore.shared.allNotes()
            if allNotes.isEmpty {
                emptyState(
                    icon: "note.text",
                    title: dailyCardStore.appLanguage == "zh-Hans" ? "暂无笔记" : "No Notes Yet",
                    subtitle: dailyCardStore.appLanguage == "zh-Hans" ? "写下你的第一篇反思" : "Write your first reflection"
                )
            } else {
                LazyVStack(spacing: 12) {
                    // Build a lookup so we can show the reference label for
                    // each note's card.
                    let cardLookup = Dictionary(
                        dailyCardStore.allCards.map { ($0.id, $0) },
                        uniquingKeysWith: { first, _ in first }
                    )
                    ForEach(allNotes, id: \.cardId) { entry in
                        let cardRef = cardLookup[entry.cardId]?.referenceText(language: dailyCardStore.appLanguage) ?? entry.cardId
                        VStack(alignment: .leading, spacing: 8) {
                            Text(cardRef)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Design.accent)
                            Text(entry.text)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "3A3A3A"))
                                .lineSpacing(5)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "FAF7F2")).shadow(color: Design.cardShadowColor, radius: 12))
                    }
                }
            }
        }
        .padding(.horizontal, Design.horizontalPadding).padding(.top, 16).padding(.bottom, 40)
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(Design.accent.opacity(0.4))
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "4A4A4A"))
            Text(subtitle).font(.system(size: 13, weight: .light)).foregroundColor(Color(hex: "9E9E9E")).multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calendar Day Cell
private struct CalendarDayCell: View {
    @EnvironmentObject var dailyCardStore: DailyCardStore
    let date: Date?

    private let calendar = Calendar.current

    // BUG FIX (P0-3): Previously this was hardcoded to return true for every
    // day 1..31, so every cell showed the "has scripture" ring. Now we look up
    // the store's persisted set of dates the user actually viewed a card on.
    private func hasScripture(for date: Date?) -> Bool {
        guard let date = date else { return false }
        return dailyCardStore.hasScripture(for: date)
    }

    var body: some View {
        ZStack {
            if let date = date {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: hasScripture(for: date) ? .semibold : .regular))
                    .foregroundColor(hasScripture(for: date) ? Design.accent : Color(hex: "9E9E9E"))
                if hasScripture(for: date) {
                    Circle().stroke(Design.accent.opacity(0.5), lineWidth: 1.5).frame(width: 28, height: 28)
                }
            }
        }
        .frame(height: 36)
        .disabled(date == nil)
    }
}
