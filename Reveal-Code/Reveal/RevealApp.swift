//
//  RevealApp.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

@main
struct VibeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var dailyCardStore = DailyCardStore.shared
    @StateObject private var shareManager = ShareManager.shared
    @State private var currentPage: AppPage = .home
    @State private var showOnboarding = false
    @State private var showSplash = true

    private var hasLaunchedBefore: Bool {
        UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(showSplash: $showSplash, isFirstLaunch: !hasLaunchedBefore) {
                    UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
                }
            } else if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .environmentObject(dailyCardStore)
            } else {
                switch currentPage {
                case .home:
                    HomeView(currentPage: $currentPage)
                        .environmentObject(themeManager)
                        .environmentObject(dailyCardStore)
                        .environmentObject(shareManager)
                case .bible:
                    BiblePassageView(currentPage: $currentPage)
                        .environmentObject(themeManager)
                        .environmentObject(dailyCardStore)
                case .calendar:
                    CalendarView(currentPage: $currentPage)
                        .environmentObject(themeManager)
                        .environmentObject(dailyCardStore)
                case .settings:
                    SettingsView(currentPage: $currentPage)
                        .environmentObject(themeManager)
                        .environmentObject(dailyCardStore)
                }
            }
        }
        .preferredColorScheme(themeManager.resolvedColorScheme)
        .animation(Design.springAnim, value: currentPage)
        .animation(Design.springAnim, value: showOnboarding)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
    }
}

enum AppPage {
    case home, bible, calendar, settings
}
