//
//  CalendarView.swift
//  Reveal
//
//  Apple-Calendar-style continuous vertical month list (P24):
//  - Replaces the prior swipe-up / swipe-down month stepper with a real
//    `ScrollView` over a window of months (24 back, 24 forward).
//  - Each month renders as a section: month title + weekday header
//    + up to 6 weeks of day cells.
//  - Tapping a day opens the same `DateDetailSheet` as before.
//
// Indicator UI (heart / pencil / dot) and the day-tap → sheet flow
// are unchanged.
//

import SwiftUI
import UIKit

// MARK: - Identifiable wrapper for .sheet(item:)
//
// We never pass `Date` directly into `.sheet(item:)` because the
// Foundation `Date : Identifiable` auto-conformance isn't reliable
// across every SDK + target combination. A small wrapper sidesteps
// that ambiguity once and for all.

struct CalendarSelection: Identifiable {
    let date: Date
    let id: String

    init(date: Date) {
        self.date = date
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        self.id = f.string(from: date)
    }
}

// MARK: - Main view

struct CalendarView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @StateObject private var notesStore: NotesStore = NotesStore.shared
    @State private var displayedMonth: Date = Date()
    @State private var selected: CalendarSelection? = nil
    // P24: one-shot guard for the "jump to today" scroll so re-renders
    // (favorite toggles, note saves) never yank the user back.
    @State private var hasScrolledToToday: Bool = false

    private let calendar: Calendar = Calendar.current

    // P24: Apple-Calendar-style vertical list. Window of months
    // centred on the current month at construction time. 24 back
    // covers ~2 years of "Scripture History"; 24 forward covers
    // ~2 years of upcoming plans / future calendar entries.
    private let monthWindowBack: Int = 24
    private let monthWindowForward: Int = 24

    // MARK: - i18n helpers

    private var weekdays: [String] {
        dailyCardStore.appLanguage == "zh-Hans"
            ? ["日", "一", "二", "三", "四", "五", "六"]
            : ["S", "M", "T", "W", "T", "F", "S"]
    }

    private var pageTitle: String {
        dailyCardStore.appLanguage == "zh-Hans" ? "经文历史" : "Scripture History"
    }

    private func monthTitle(_ month: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = dailyCardStore.appLanguage == "zh-Hans" ? "yyyy 年 M 月" : "MMMM yyyy"
        return f.string(from: month)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            calendarBackground
            VStack(spacing: 0) {
                topNav
                appleCalendarList
            }
        }
        .sheet(item: $selected) { (selection: CalendarSelection) in
            DateDetailSheet(
                date: selection.date,
                card: self.cardForDate(selection.date),
                language: self.dailyCardStore.appLanguage,
                onDismiss: { self.selected = nil }
            )
            .environmentObject(self.dailyCardStore)
            .environmentObject(self.themeManager)
        }
    }

    // MARK: - Top navigation

    private var topNav: some View {
        HStack {
            BackCircleButton {
                MainActor.assumeIsolated {
                    self.currentPage = .home
                }
            }
            Spacer()
            Text(pageTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(foregroundText)
            Spacer()
            Color.clear.frame(width: Design.iconButtonSize, height: Design.iconButtonSize)
        }
        .padding(.horizontal, Design.horizontalPadding)
        .padding(.top, 16)
    }

    // MARK: - P24 Apple-style list

    private var appleCalendarList: some View {
        // `ScrollViewReader` is used so we can open the calendar at
        // today's section — matches the system Calendar app's
        // behaviour of jumping straight to today on launch.
        //
        // Months are tagged by their **index** in `monthsToShow`, not
        // by the `Date` itself. `Date` is a `Hashable` value type whose
        // hashing includes sub-second precision, so two `Date`s that
        // mean "the same month" can fail an `==` / hash comparison and
        // `proxy.scrollTo(date)` would then silently no-op. Indices
        // are always exact.
        let monthCount = monthsToShow.count
        let todayIndex = monthsToShow.firstIndex { month in
            calendar.isDate(month, equalTo: Date(), toGranularity: .month)
        }

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(monthsToShow.enumerated()), id: \.offset) { index, month in
                        monthSection(month).id(index)
                    }
                }
                .padding(.horizontal, Design.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            // P24: auto-scroll to today's section. Guarded by a
            // one-shot flag so the jump happens exactly once per view
            // appearance — re-running it on every re-render (e.g. after
            // toggling a favorite) would yank the user back to today
            // mid-scroll. The short delay lets `LazyVStack` lay out the
            // first frame; without it `scrollTo` can resolve before any
            // row has been measured and does nothing.
            .onAppear {
                guard let todayIndex,
                      !hasScrolledToToday,
                      todayIndex >= 0,
                      todayIndex < monthCount
                else { return }
                hasScrolledToToday = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(todayIndex, anchor: .center)
                }
            }
        }
    }

    private func monthSection(_ month: Date) -> some View {
        VStack(spacing: 0) {
            // Section header — month + year, mirroring Apple's own
            // monthly view typography.
            HStack {
                Text(monthTitle(month))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(foregroundText)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Weekday header.
            HStack(spacing: 0) {
                // Keyed by position: the letters are not unique ("S"
                // and "T" appear twice); `id: \.self` on duplicates
                // dropped cells before.
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, w in
                    Text(w)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(weekdayColor)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)

            // Week rows.
            VStack(spacing: 0) {
                ForEach(weeksForMonth(month), id: \.self) { week in
                    CalendarWeekRow(
                        week: week,
                        sectionMonth: month,
                        hasNote: self.hasNote(for:),
                        hasFavorite: self.hasFavorite(for:),
                        hasScripture: self.hasScripture(for:),
                        isDark: self.isDark,
                        onTap: { (date: Date) in
                            MainActor.assumeIsolated {
                                self.selected = CalendarSelection(date: date)
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(calendarCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 16)
    }

    // MARK: - Month / week helpers

    private var monthsToShow: [Date] {
        let cal = Calendar.current
        let base = cal.date(
            from: cal.dateComponents([.year, .month], from: displayedMonth)
        ) ?? displayedMonth
        return (-monthWindowBack ... monthWindowForward).compactMap { offset in
            cal.date(byAdding: .month, value: offset, to: base)
        }
    }

    /// Up to 6 weeks (each row = 7 `Date`s) for `month`. The first
    /// row starts at the weekday on or before the 1st (per
    /// `Calendar.current.firstWeekday`), the last row ends at the
    /// weekday on or after the last day of the month. Dates that
    /// fall in neighbouring months are still part of their row —
    /// they end up dimmed in the cell view (`sectionMonth` check),
    /// matching the system Calendar's first / last-week padding.
    private func weeksForMonth(_ month: Date) -> [[Date]] {
        let cal = Calendar.current
        guard let firstOfMonth = cal.date(
            from: cal.dateComponents([.year, .month], from: month)
        ),
        let range = cal.range(of: .day, in: .month, for: firstOfMonth),
        let lastOfMonth = cal.date(byAdding: .day, value: range.count - 1, to: firstOfMonth)
        else { return [] }

        let firstWeekday = cal.firstWeekday
        let lead = (cal.component(.weekday, from: firstOfMonth) - firstWeekday + 7) % 7
        let daysFromWeekStart = (cal.component(.weekday, from: lastOfMonth) - firstWeekday + 7) % 7
        let trail = 6 - daysFromWeekStart

        guard let startDate = cal.date(byAdding: .day, value: -lead, to: firstOfMonth),
              let endDate = cal.date(byAdding: .day, value: trail, to: lastOfMonth)
        else { return [] }

        var weeks: [[Date]] = []
        var cursor = startDate
        while cursor <= endDate {
            let week = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: cursor) }
            weeks.append(week)
            guard let next = cal.date(byAdding: .day, value: 7, to: cursor) else { break }
            cursor = next
        }
        return weeks
    }

    // MARK: - Date helpers

    private func cardForDate(_ date: Date) -> RevealCard? {
        dailyCardStore.previewCard(for: date)
    }

    private func hasScripture(for date: Date?) -> Bool {
        guard let d = date else { return false }
        return dailyCardStore.hasScripture(for: d)
    }

    private func hasNote(for date: Date?) -> Bool {
        guard let d = date, let card = cardForDate(d) else { return false }
        return !notesStore.note(for: card.id).isEmpty
    }

    private func hasFavorite(for date: Date?) -> Bool {
        guard let d = date, let card = cardForDate(d) else { return false }
        return dailyCardStore.isFavorite(card.id)
    }

    // MARK: - Colors

    private var isDark: Bool {
        switch themeManager.appearanceMode {
        case .system: return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:  return false
        case .dark:   return true
        }
    }

    private var calendarBackground: some View {
        Group {
            if self.isDark {
                Color.black
            } else {
                Color(hex: "F2F0EB")
            }
        }
        .ignoresSafeArea()
    }

    private var calendarCardBackground: some View {
        isDark ? Color(white: 0.10) : Color.white
    }

    private var foregroundText: Color {
        isDark ? Color.white : Color(hex: "1C1C1E")
    }

    private var weekdayColor: Color {
        Color(hex: "8E8E93")
    }
}

// MARK: - Calendar week row
//
// P24: replaces the in-grid `CalendarDayCell` for the scrollable
// list. One row holds 7 fixed dates; out-of-section dates (Sept 27
// in October's first row, etc.) are dimmed in `dayColor`.

private struct CalendarWeekRow: View {
    let week: [Date]
    let sectionMonth: Date
    let hasNote: (Date?) -> Bool
    let hasFavorite: (Date?) -> Bool
    let hasScripture: (Date?) -> Bool
    let isDark: Bool
    let onTap: (Date) -> Void

    private let calendar: Calendar = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(week, id: \.self) { date in
                Button(action: { self.onTap(date) }) {
                    self.cellBody(date)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func cellBody(_ date: Date) -> some View {
        let dayNum = "\(calendar.component(.day, from: date))"
        let isToday = calendar.isDateInToday(date)
        let inSection = calendar.isDate(date, equalTo: sectionMonth, toGranularity: .month)
        return VStack(spacing: 2) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Design.accent)
                        .frame(width: 30, height: 30)
                }
                Text(dayNum)
                    .font(.system(
                        size: 16,
                        weight: isToday
                            ? .bold
                            : ((hasScripture(date) || hasNote(date) || hasFavorite(date))
                                ? .medium : .regular)
                    ))
                    .foregroundColor(self.dayColor(isToday: isToday, inSection: inSection))
            }
            .frame(height: 34)

            // Indicator dots row (favorite / note / scripture).
            // Rendered for every cell so the rhythm of the row
            // stays even when neighbour-month days are dimmed.
            HStack(spacing: 2) {
                if hasFavorite(date) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Design.accent)
                }
                if hasNote(date) {
                    Image(systemName: "pencil")
                        .font(.system(size: 6))
                        .foregroundColor(Design.accent)
                }
                if hasScripture(date) && !hasNote(date) && !hasFavorite(date) {
                    Circle()
                        .fill(Design.accent.opacity(0.5))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 10)
        }
    }

    private func dayColor(isToday: Bool, inSection: Bool) -> Color {
        if isToday { return Color.white }
        if !inSection { return Color(hex: "8E8E93") } // P24: dim neighbour-month day numbers
        return isDark ? Color.white : Color(hex: "1C1C1E")
    }
}

// MARK: - Calendar day cell
//
// P24: kept here so the file remains a single source of truth for
// the calendar UI. Currently unused — the scrollable list above
// renders its own row via `CalendarWeekRow`. The tap → sheet +
// indicator dot logic is now embedded in `CalendarWeekRow.cellBody`.
// If the legacy single-month grid is ever needed again, this cell
// is ready to drop back into a `LazyVGrid`.

private struct CalendarDayCell: View {
    @EnvironmentObject var themeManager: ThemeManager
    let date: Date?
    let hasNote: Bool
    let hasFavorite: Bool
    let hasScripture: Bool
    let onTap: () -> Void

    private let calendar: Calendar = Calendar.current

    private var isDark: Bool {
        switch themeManager.appearanceMode {
        case .system: return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:  return false
        case .dark:   return true
        }
    }

    private var isToday: Bool {
        guard let d = date else { return false }
        return calendar.isDateInToday(d)
    }

    var body: some View {
        Button(action: {
            MainActor.assumeIsolated {
                if date != nil { onTap() }
            }
        }) {
            VStack(spacing: 2) {
                if let d = date {
                    let dayNum: String = "\(calendar.component(.day, from: d))"
                    ZStack {
                        if self.isToday {
                            Circle()
                                .fill(Design.accent)
                                .frame(width: 30, height: 30)
                        }
                        Text(dayNum)
                            .font(.system(
                                size: 16,
                                weight: self.isToday
                                    ? .bold
                                    : ((self.hasScripture || self.hasNote || self.hasFavorite)
                                       ? .medium : .regular)
                            ))
                            .foregroundColor(self.dayNumberColor(isToday: self.isToday))
                    }
                    .frame(height: 34)

                    // Indicator dots row (favorite / note / scripture).
                    HStack(spacing: 2) {
                        if self.hasFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 6))
                                .foregroundColor(Design.accent)
                        }
                        if self.hasNote {
                            Image(systemName: "pencil")
                                .font(.system(size: 6))
                                .foregroundColor(Design.accent)
                        }
                        if self.hasScripture && !self.hasNote && !self.hasFavorite {
                            Circle()
                                .fill(Design.accent.opacity(0.5))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 10)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(date == nil)
    }

    private func dayNumberColor(isToday: Bool) -> Color {
        if isToday { return Color.white }
        return isDark ? Color.white : Color(hex: "1C1C1E")
    }
}

// MARK: - Date detail sheet

private struct DateDetailSheet: View {
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @StateObject private var notesStore: NotesStore = NotesStore.shared
    @EnvironmentObject var themeManager: ThemeManager

    let date: Date
    let card: RevealCard?
    let language: String
    let onDismiss: () -> Void

    @State private var noteText: String = ""
    @State private var isEditingNote: Bool = false

    private var isDark: Bool {
        switch themeManager.appearanceMode {
        case .system: return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:  return false
        case .dark:   return true
        }
    }

    private var sheetBackground: Color {
        isDark ? Color.black : Color(hex: "F2F0EB")
    }

    private var cardBackground: Color {
        isDark ? Color(white: 0.10) : Color.white
    }

    private var primaryText: Color {
        isDark ? Color.white : Color(hex: "1C1C1E")
    }

    private var placeholderText: Color {
        Color(hex: "C7C7CC")
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = language == "zh-Hans" ? "M月d日" : "MMMM d"
        return f.string(from: date)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    self.headerSection
                    if let c = self.card {
                        self.cardSection(c)
                        self.noteSection(c)
                    } else {
                        self.emptySection
                    }
                }
                .padding(.horizontal, Design.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(self.sheetBackground)
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: { self.onDismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            )
        }
        .onAppear {
            // The onAppear closure is non-MainActor, but loadNote() is
            // @MainActor. Dispatching onto MainActor is a no-op at runtime
            // here (we're already there) and satisfies strict concurrency.
            MainActor.assumeIsolated {
                self.loadNote()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.dateLabel)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(self.primaryText)
            if let c = self.card {
                Text(c.referenceText(language: self.language))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Design.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cardSection(_ card: RevealCard) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\"\(card.verseText(language: self.language))\"")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(self.primaryText)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)

                Text(card.questionText(language: self.language))
                    .font(.system(size: 14))
                    .foregroundColor(self.primaryText.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(self.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Favorite toggle row
            Button(action: {
                self.dailyCardStore.toggleFavorite(card.id)
            }) {
                HStack {
                    Image(systemName: self.dailyCardStore.isFavorite(card.id) ? "heart.fill" : "heart")
                        .foregroundColor(Design.accent)
                    Text(self.dailyCardStore.isFavorite(card.id)
                         ? (self.language == "zh-Hans" ? "已收藏" : "Favorited")
                         : (self.language == "zh-Hans" ? "添加收藏" : "Add to Favorites"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(self.primaryText)
                    Spacer()
                }
                .padding(16)
                .background(self.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func noteSection(_ card: RevealCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 13))
                    .foregroundColor(Design.accent)
                Text(self.language == "zh-Hans" ? "笔记" : "Note")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(self.primaryText)
            }

            if self.noteText.isEmpty {
                Button(action: { self.isEditingNote = true }) {
                    HStack {
                        Text(self.language == "zh-Hans" ? "写笔记…" : "Write a note…")
                            .font(.system(size: 14))
                            .foregroundColor(self.placeholderText)
                        Spacer()
                    }
                    .padding(16)
                    .background(self.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.noteText)
                        .font(.system(size: 14))
                        .foregroundColor(self.primaryText)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack {
                        Spacer()
                        Button(action: { self.isEditingNote = true }) {
                            Text(self.language == "zh-Hans" ? "编辑" : "Edit")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Design.accent)
                        }
                    }
                }
                .padding(16)
                .background(self.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: self.$isEditingNote, onDismiss: {
            MainActor.assumeIsolated {
                self.isEditingNote = false
            }
        }) {
            NoteEditSheet(
                cardId: card.id,
                language: self.language,
                initialText: self.noteText,
                onCancel: {
                    MainActor.assumeIsolated {
                        self.isEditingNote = false
                    }
                }
            ) { (newText: String) in
                self.noteText = newText
                self.notesStore.noteText = newText
                self.notesStore.save()
            }
        }
    }

    private var emptySection: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "C7C7CC"))
            Text(self.language == "zh-Hans"
                 ? "这天还没有打开过"
                 : "No card viewed on this day")
                .font(.system(size: 15))
                .foregroundColor(self.placeholderText)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    private func loadNote() {
        guard let c = self.card else { return }
        self.noteText = self.notesStore.note(for: c.id)
    }
}

// MARK: - Note edit sheet

private struct NoteEditSheet: View {
    let cardId: String
    let language: String
    let initialText: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @State private var text: String = ""
    @EnvironmentObject var themeManager: ThemeManager

    private var isDark: Bool {
        switch themeManager.appearanceMode {
        case .system: return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:  return false
        case .dark:   return true
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                self.textEditor
                    .onAppear {
                        MainActor.assumeIsolated {
                            self.text = self.initialText
                        }
                    }
            }
            .background(self.isDark ? Color.black : Color(hex: "F2F0EB"))
            .navigationBarTitle(
                Text(self.language == "zh-Hans" ? "编辑笔记" : "Edit Note"),
                displayMode: .inline
            )
            .navigationBarItems(
                leading: Button(action: { self.onCancel() }) {
                    Text(self.language == "zh-Hans" ? "取消" : "Cancel")
                        .foregroundColor(Design.accent)
                },
                trailing: Button(action: {
                    self.onSave(self.text)
                    self.onCancel()
                }) {
                    Text(self.language == "zh-Hans" ? "保存" : "Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Design.accent)
                }
            )
        }
    }

    @ViewBuilder
    private var textEditor: some View {
        let editor = TextEditor(text: self.$text)
            .font(.system(size: 16))
            .padding(16)
            .background(self.isDark ? Color(white: 0.10) : Color.white)

        if #available(iOS 16.0, *) {
            editor.scrollContentBackground(.hidden)
        } else {
            editor
        }
    }
}
