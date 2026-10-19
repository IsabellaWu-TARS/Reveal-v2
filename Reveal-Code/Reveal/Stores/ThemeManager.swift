//
//  ThemeManager.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

@MainActor
class ThemeManager: ObservableObject {
    @Published var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "AppearanceMode") }
    }

    enum AppearanceMode: String, CaseIterable {
        case system = "system", light = "light", dark = "dark"
        var titleZH: String {
            switch self {
            case .system: return "跟随系统"
            case .light: return "浅色模式"
            case .dark: return "深色模式"
            }
        }
        var titleEN: String {
            switch self {
            case .system: return "Follow System"
            case .light: return "Light Mode"
            case .dark: return "Dark Mode"
            }
        }
        func title(for lang: String) -> String {
            lang == "zh-Hans" ? titleZH : titleEN
        }
    }

    var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "AppearanceMode") ?? AppearanceMode.system.rawValue
        appearanceMode = AppearanceMode(rawValue: raw) ?? .system
    }
}
