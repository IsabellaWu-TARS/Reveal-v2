//
//  FavoriteEntry.swift
//  Reveal
//
//  SwiftData table for cards the user has favorited (heart icon on the back).
//
//  Replaces UserDefaults["FavoriteCardIds"], which was a flat `[String]`
//  with no timestamp – we couldn't tell when a user fell in love with a
//  verse, only that they had. Now we can show "recently favorited" and
//  sort by favorite time (newest first, oldest last).
//

import Foundation
import SwiftData

@Model
final class FavoriteEntry {
    /// Card id, e.g. "psalm-23-1".
    @Attribute(.unique) var cardId: String

    /// When the user toggled it on (we don't track toggles-off events –
    /// deleting the row IS the toggle-off).
    var favoritedAt: Date

    init(cardId: String, favoritedAt: Date = .now) {
        self.cardId = cardId
        self.favoritedAt = favoritedAt
    }
}
