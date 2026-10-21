//
//  ViewedDateEntry.swift
//  Reveal
//
//  SwiftData table for calendar days the user has actually opened the home
//  screen on. The Calendar tab uses this to mark dates that had a scripture
//  card displayed to the user.
//
//  Replaces UserDefaults["ViewedDates"], which was a flat `[String]` of
//  "yyyy-MM-dd" keys with no join capability. Same shape, but now a proper
//  indexed table so we can scale to years of viewing history without
//  rewriting the whole list each time.
//

import Foundation
import SwiftData

@Model
final class ViewedDateEntry {
    /// Calendar day in `yyyy-MM-dd` form (matches the existing key format
    /// used by `DailyCardStore.todayDateKey()`).
    @Attribute(.unique) var dateKey: String

    /// First time the user opened the home screen on this date.
    /// We only ever insert (never update) because a calendar-day is
    /// discrete – re-opening on the same day shouldn't bump the timestamp.
    var firstViewedAt: Date

    init(dateKey: String, firstViewedAt: Date = .now) {
        self.dateKey = dateKey
        self.firstViewedAt = firstViewedAt
    }
}
