import SwiftUI

// MARK: - Design System
struct LiquidGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial) // The "Glass" effect
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
    }
}

extension Color {
    static let revealGreen = Color(red: 0.2, green: 0.6, blue: 0.3) // Nature Green
    static let revealBeige = Color(red: 0.96, green: 0.96, blue: 0.90) // Light Beige
    static let revealGradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2), Color.pink.opacity(0.2)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func liquidGlassStyle() -> some View {
        self.modifier(LiquidGlass())
    }
}

struct ScriptureOfDay: Identifiable {
    let id = UUID()
    let verseRef: String
    let text: String
    let reflectionQuestion: String
    let keyLesson: String
    let action: String
    let fullPassage: String
}

// Mock Data
let todayScripture = ScriptureOfDay(
    verseRef: "Psalm 145:18",
    text: "The Lord is near to all who call on him, to all who call on him in truth.",
    reflectionQuestion: "What does it mean to 'call on God in truth'?",
    keyLesson: "God's presence is accessible.",
    action: "Pray honestly today about your struggles.",
    fullPassage: "Psalm 145 (Full Text Here...)"
)

// SplashView and OnboardingView are now defined in VibeApp.swift
