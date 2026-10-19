//
//  NotesStore.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class NotesStore: ObservableObject {
    static let shared = NotesStore()
    @Published var noteText: String = ""
    @Published var isNoteEditorPresented: Bool = false
    @Published var noteDate: Date = Date()
    /// Currently selected card id (set by views when the user opens the editor).
    @Published var currentCardId: String = ""

    // BUG FIX (P1-3): Notes used to be a single global string overwritten
    // every time a different card was opened. Now we store a dictionary
    // keyed by card id, so each card keeps its own reflection note.
    private let notesKey = "UserNotesByCardId"
    private let dateKey  = "UserNoteDate"

    private init() {
        // Migrate from old single-note storage if it exists, using card 0
        // (the onboarding card) as the migration target so we don't lose data.
        if let legacy = UserDefaults.standard.string(forKey: "UserNoteText"),
           !legacy.isEmpty,
           let dict = UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String],
           dict.isEmpty {
            UserDefaults.standard.set([String(legacySplitGuess()): legacy], forKey: notesKey)
            UserDefaults.standard.removeObject(forKey: "UserNoteText")
        }

        if let ts = UserDefaults.standard.object(forKey: dateKey) as? TimeInterval {
            noteDate = Date(timeIntervalSince1970: ts)
        }
    }

    private func legacySplitGuess() -> String {
        // First card id we ship with
        return "genesis-1-1"
    }

    /// Load the saved text for a card (call this when opening the editor).
    func loadNote(for cardId: String) -> String {
        let dict = (UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String]) ?? [:]
        currentCardId = cardId
        let text = dict[cardId] ?? ""
        noteText = text
        return text
    }

    /// Save the current noteText into the slot for the current card id.
    func save() {
        guard !currentCardId.isEmpty else { return }
        var dict = (UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String]) ?? [:]
        dict[currentCardId] = noteText
        UserDefaults.standard.set(dict, forKey: notesKey)
        UserDefaults.standard.set(noteDate.timeIntervalSince1970, forKey: dateKey)
    }

    /// Return all saved notes (for the Calendar "Notes" tab).
    func allNotes() -> [(cardId: String, text: String)] {
        let dict = (UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String]) ?? [:]
        return dict.map { ($0.key, $0.value) }
    }

    /// Plain reading of the current text for one card, without mutating state.
    func note(for cardId: String) -> String {
        let dict = (UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String]) ?? [:]
        return dict[cardId] ?? ""
    }
}
