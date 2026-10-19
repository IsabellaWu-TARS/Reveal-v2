//
//  ShareManager.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class ShareManager: ObservableObject {
    static let shared = ShareManager()
    @Published var showShareOptions: Bool = false
    @Published var showShareSheet: Bool = false
    @Published var shareMode: ShareMode = .verse

    enum ShareMode: String, CaseIterable {
        case verse = "verse"
        case reflection = "reflection"
        case note = "note"
        case fullSet = "fullSet"

        func titleZH(lang: String) -> String {
            switch self {
            case .verse: return "分享经文"
            case .reflection: return "分享默想"
            case .note: return "分享笔记"
            case .fullSet: return "分享完整内容"
            }
        }
        func titleEN(lang: String) -> String {
            switch self {
            case .verse: return "Share Verse"
            case .reflection: return "Share Reflection"
            case .note: return "Share Note"
            case .fullSet: return "Share Full Set"
            }
        }
        func subtitleZH() -> String {
            switch self {
            case .verse: return "分享经文卡片"
            case .reflection: return "分享默想内容"
            case .note: return "分享我的反思笔记"
            case .fullSet: return "经文 + 默想 + 笔记"
            }
        }
        func subtitleEN() -> String {
            switch self {
            case .verse: return "Share the verse card"
            case .reflection: return "Share the reflection side"
            case .note: return "Share your reflection note"
            case .fullSet: return "Verse + reflection + note"
            }
        }
        var iconName: String {
            switch self {
            case .verse: return "quote.bubble.fill"
            case .reflection: return "questionmark.bubble.fill"
            case .note: return "note.text"
            case .fullSet: return "square.stack.3d.up.fill"
            }
        }
    }

    private init() {}
}
