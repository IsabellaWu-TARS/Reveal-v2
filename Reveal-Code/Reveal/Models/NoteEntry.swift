//
//  NoteEntry.swift
//  Reveal
//
//  SwiftData table for user-written reflections, one row per scripture card.
//
//  Replaces the previous UserDefaults-dict-at-`UserNotesByCardId` storage,
//  which had three problems:
//    1. no per-card edit timestamp (only one global `UserNoteDate`),
//    2. no way to enumerate / sort / paginate cleanly,
//    3. didn't scale past a couple thousand entries.
//
//  Migration of the old dict into this table happens once, on first launch,
//  in `DataMigrator.swift`.
//

import Foundation
import SwiftData

@Model
final class NoteEntry {
    /// The id of the card the note belongs to (e.g. "genesis-1-1").
    /// Unique because the same card can only have one live reflection at a time.
    @Attribute(.unique) var cardId: String

    /// Raw note text. Empty string = "this card has no live note right now"
    /// (we delete the row instead of keeping an empty placeholder). The
    /// row is recreated next time the user starts typing, so `createdAt`
    /// resets to the new writing session – that's intentional: an empty
    /// note has no meaningful history.
    var text: String

    /// Last time the user typed into the editor for THIS card.
    /// Replaces the old global `UserNoteDate` field.
    var lastEditedAt: Date

    /// First time this note was ever created (survives edits).
    /// Useful for "show me all notes I've ever written, newest edit first"
    /// vs "show me my earliest writings".
    var createdAt: Date

    init(
        cardId: String,
        text: String,
        lastEditedAt: Date = .now,
        createdAt: Date = .now
    ) {
        self.cardId = cardId
        self.text = text
        self.lastEditedAt = lastEditedAt
        self.createdAt = createdAt
    }
}
