import SwiftUI
import Combine
import UIKit

// MARK: - App Entry Point
@main
struct VibeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Main App Structure
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

// MARK: - App Pages Enum
enum AppPage {
    case home, bible, calendar, settings
}

// MARK: - Haptic Feedback
enum HapticManager {
    static func light() { let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred() }
    static func medium() { let g = UIImpactFeedbackGenerator(style: .medium); g.impactOccurred() }
    static func soft() { let g = UIImpactFeedbackGenerator(style: .soft); g.impactOccurred() }
    static func success() { let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success) }
}

// MARK: - Design Constants
struct Design {
    static let accent = Color(hex: "A2A569")
    static let lightBackground = Color(hex: "FFFAE3")
    static let lightSurface = Color(hex: "FFF7D6")
    static let cardShadowColor = Color.black.opacity(0.08)
    static let cardRadius: CGFloat = 32
    static let notesRadius: CGFloat = 28
    static let springAnim = Animation.spring(response: 0.45, dampingFraction: 0.85)

    // Card gradient palettes
    static let pinkGradient    = [Color(hex: "E8A5A5"), Color(hex: "F5D4D4")]
    static let blueGradient   = [Color(hex: "B7E4F0"), Color(hex: "D8C8F4")]
    static let sageGradient   = [Color(hex: "C5D5A0"), Color(hex: "D8E8B5")]
    static let warmGradient   = [Color(hex: "F5D4A0"), Color(hex: "FAE8C8")]
    static let lavenderGradient = [Color(hex: "D8C8F4"), Color(hex: "E8D8F8")]
    static let mintGradient   = [Color(hex: "B7E4D4"), Color(hex: "D8F0E8")]
    static let peachGradient  = [Color(hex: "F5C4A0"), Color(hex: "FAE0C8")]

    static let allGradients: [[Color]] = [pinkGradient, blueGradient, sageGradient, warmGradient, lavenderGradient, mintGradient, peachGradient]

    static func gradientForDay(_ day: Int) -> [Color] {
        allGradients[day % allGradients.count]
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:   (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:   (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:   (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:  (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - App Background
struct AppBackground: View {
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            if isDark {
                LinearGradient(colors: [Color(hex: "1E1E1E"), Color(hex: "111111")], startPoint: .top, endPoint: .bottom)
            } else {
                Color(hex: "FFFAE3")
            }
            Image(systemName: "leaf.fill")
                .resizable().aspectRatio(contentMode: .fit).frame(width: 450, height: 450)
                .foregroundColor(Design.accent.opacity(isDark ? 0.04 : 0.06))
                .blur(radius: isDark ? 20 : 30)
                .offset(x: -100, y: -280)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @Binding var showSplash: Bool
    let isFirstLaunch: Bool
    let onFirstLaunchComplete: () -> Void

    @State private var opacityText: Double = 0
    @State private var scaleText: CGFloat = 0.7
    @State private var opacityIcon: Double = 0
    @State private var scaleIcon: CGFloat = 0.7

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if isFirstLaunch {
                // First screen: welcome text
                VStack(spacing: 16) {
                    Text("Welcome To")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Design.accent)
                    Text("Reveal Mashal")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                .opacity(opacityText)
                .scaleEffect(scaleText)
            } else {
                // Normal splash: app icon
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(LinearGradient(colors: [Color(hex: "E8F5E9"), Color(hex: "C8E6C9")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 160)
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(Design.accent.opacity(0.5), lineWidth: 2))
                        .shadow(color: Color(hex: "4CAF50").opacity(0.2), radius: 20)

                    LeafShape()
                        .fill(LinearGradient(colors: [Design.accent, Color(hex: "B8C48A"), Color(hex: "A8B89A")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 110)
                        .overlay(LeafVeinsShape().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                        .overlay(Text("R").font(.custom("Georgia", size: 44)).fontWeight(.bold).foregroundColor(Color.white.opacity(0.95)).offset(x: 0, y: -6))
                }
                .opacity(opacityIcon)
                .scaleEffect(scaleIcon)
            }
        }
        .onAppear {
            if isFirstLaunch {
                withAnimation(.easeOut(duration: 0.8)) { opacityText = 1.0; scaleText = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) { opacityText = 0; scaleText = 1.1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.8)) { opacityIcon = 1.0; scaleIcon = 1.0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) { opacityIcon = 0; scaleIcon = 0.9 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onFirstLaunchComplete()
                                withAnimation { showSplash = false }
                            }
                        }
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.6)) { opacityIcon = 1.0; scaleIcon = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) { opacityIcon = 0; scaleIcon = 0.9 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showSplash = false }
                }
            }
        }
    }
}

// MARK: - Leaf Shape
struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.95))
        p.addCurve(to: CGPoint(x: w * 0.2, y: h * 0.3), control1: CGPoint(x: w * 0.35, y: h * 0.7), control2: CGPoint(x: w * 0.25, y: h * 0.5))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.05), control1: CGPoint(x: w * 0.3, y: h * 0.15), control2: CGPoint(x: w * 0.4, y: h * 0.08))
        p.addCurve(to: CGPoint(x: w * 0.8, y: h * 0.3), control1: CGPoint(x: w * 0.6, y: h * 0.08), control2: CGPoint(x: w * 0.7, y: h * 0.15))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.95), control1: CGPoint(x: w * 0.75, y: h * 0.5), control2: CGPoint(x: w * 0.65, y: h * 0.7))
        p.closeSubpath()
        return p
    }
}

// MARK: - Leaf Veins
struct LeafVeinsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.95)); p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.05))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.4)); p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.35))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.5)); p.addLine(to: CGPoint(x: w * 0.28, y: h * 0.45))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.6)); p.addLine(to: CGPoint(x: w * 0.32, y: h * 0.65))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.4)); p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.35))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.5)); p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.45))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.6)); p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.65))
        return p
    }
}

// MARK: - Theme Manager
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

// MARK: - Card Models
struct BilingualCardContent: Codable {
    let verse: String
    let question: String
    let action: String
}

struct RevealCard: Identifiable, Codable {
    let id: String
    let reference: String
    let book: String
    let chapter: Int
    let verse: Int
    let en: BilingualCardContent
    let zh: BilingualCardContent

    func verseText(language: String) -> String {
        language == "zh-Hans" ? (zh.verse.isEmpty ? en.verse : zh.verse) : en.verse
    }
    func questionText(language: String) -> String {
        language == "zh-Hans" ? (zh.question.isEmpty ? en.question : zh.question) : en.question
    }
    func actionText(language: String) -> String {
        language == "zh-Hans" ? zh.action : en.action
    }
}

// MARK: - Card Mirror State
enum CardMirrorState: Int { case front, back }

// MARK: - Seeded RNG
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Daily Card Store
@MainActor
final class DailyCardStore: ObservableObject {
    static let shared = DailyCardStore()

    @Published private(set) var todayDateKey: String = ""
    @Published private(set) var currentCard: RevealCard?
    @Published private(set) var mirrorState: CardMirrorState = .front
    @Published private(set) var transitionAngle: Double = 0
    @Published private(set) var appLanguage: String = "en"
    @Published private(set) var allCards: [RevealCard] = []
    @Published private(set) var seenCardIds: Set<String> = []
    @Published private(set) var favoriteIds: Set<String> = []

    private var seededRNG: SeededRNG = SeededRNG(seed: 1)
    private var seed: UInt64 = 0
    private var currentIndex: Int = 0

    private init() {
        todayDateKey = Self.todayDateKey()
        seed = Self.dailySeed()
        seededRNG = SeededRNG(seed: seed)
        appLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? "en"
        loadFavorites()
        allCards = Self.loadCards()
        advanceToTodayCard()
    }

    func setLanguage(_ language: String) {
        appLanguage = language
        UserDefaults.standard.set(language, forKey: "AppLanguage")
    }

    private func advanceToTodayCard() {
        guard !allCards.isEmpty else { return }
        if seenCardIds.count >= allCards.count {
            seenCardIds.removeAll()
            seed = Self.dailySeed()
            seededRNG = SeededRNG(seed: seed)
        }
        var gen = seededRNG
        let unseenIndices = allCards.indices.filter { !seenCardIds.contains(allCards[$0].id) }
        guard !unseenIndices.isEmpty else { return }
        let idx = unseenIndices[Int.random(in: 0..<unseenIndices.count, using: &gen)]
        currentCard = allCards[idx]
        seenCardIds.insert(allCards[idx].id)
        currentIndex = idx
        mirrorState = .front
        transitionAngle = 0
    }

    func flip() {
        HapticManager.soft()
        withAnimation(Design.springAnim) {
            mirrorState = mirrorState == .front ? .back : .front
            transitionAngle += 180
        }
    }

    func toggleFavorite(_ cardId: String) {
        HapticManager.success()
        if favoriteIds.contains(cardId) { favoriteIds.remove(cardId) }
        else { favoriteIds.insert(cardId) }
        saveFavorites()
    }

    func isFavorite(_ cardId: String) -> Bool { favoriteIds.contains(cardId) }

    func nextCard() {
        advanceToTodayCard()
    }

    private func loadFavorites() {
        favoriteIds = Set(UserDefaults.standard.stringArray(forKey: "FavoriteCardIds") ?? [])
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: "FavoriteCardIds")
    }

    var isFront: Bool { mirrorState == .front }

    private static func todayDateKey() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }

    private static func dailySeed() -> UInt64 {
        let dateStr = todayDateKey()
        var h = dateStr.hashValue
        if h < 0 { h = -h }
        return h == 0 ? 1 : UInt64(h)
    }

    private static func loadCards() -> [RevealCard] {
        guard let url = Bundle.main.url(forResource: "RevealCards_bilingual", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cards = try? JSONDecoder().decode([RevealCard].self, from: data) else { return [] }
        return cards
    }

    func cardForOnboarding(at index: Int) -> RevealCard? {
        guard !allCards.isEmpty else { return nil }
        return allCards[index % allCards.count]
    }

    var totalCards: Int { allCards.count }
}

// MARK: - Notes Store
@MainActor
final class NotesStore: ObservableObject {
    static let shared = NotesStore()
    @Published var noteText: String = ""
    @Published var isNoteEditorPresented: Bool = false
    @Published var noteDate: Date = Date()
    private let key = "UserNoteText"
    private let dateKey = "UserNoteDate"
    private init() {
        noteText = UserDefaults.standard.string(forKey: key) ?? ""
        if let ts = UserDefaults.standard.object(forKey: dateKey) as? TimeInterval {
            noteDate = Date(timeIntervalSince1970: ts)
        }
    }
    func save() {
        UserDefaults.standard.set(noteText, forKey: key)
        UserDefaults.standard.set(noteDate.timeIntervalSince1970, forKey: dateKey)
    }
}

// MARK: - Share Manager
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

// MARK: - Home View
struct HomeView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @EnvironmentObject var shareManager: ShareManager
    @StateObject private var notesStore = NotesStore.shared
    @State private var cardDayIndex: Int = 0

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    HomeCircleButton(icon: "book.fill") {
                        HapticManager.light()
                        withAnimation { currentPage = .bible }
                    }
                    Spacer()
                    HomeCircleButton(icon: "calendar") {
                        HapticManager.light()
                        withAnimation { currentPage = .calendar }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 60)

                Spacer()

                // Card
                if let card = dailyCardStore.currentCard {
                    cardContent(card: card)
                } else {
                    ProgressView()
                        .frame(height: 500)
                }

                Spacer()

                // Bottom bar: Bible | Share | Notes | Settings
                bottomBar
                    .padding(.bottom, 32)
            }

            // Notes overlay
            if notesStore.isNoteEditorPresented {
                notesExpandOverlay
            }

            // Share options
            if shareManager.showShareOptions {
                shareOptionsOverlay
            }
        }
        .onAppear {
            cardDayIndex = Calendar.current.component(.day, from: Date())
        }
    }

    // MARK: - Card Content
    @ViewBuilder
    private func cardContent(card: RevealCard) -> some View {
        ZStack {
            // Back side
            CardBackView(
                card: card,
                language: dailyCardStore.appLanguage,
                onFavorite: { dailyCardStore.toggleFavorite(card.id) },
                isFavorite: dailyCardStore.isFavorite(card.id)
            )
            .opacity(dailyCardStore.isFront ? 0 : 1)
            .rotation3DEffect(.degrees(dailyCardStore.transitionAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)

            // Front side
            CardFrontView(
                card: card,
                language: dailyCardStore.appLanguage,
                gradient: Design.gradientForDay(cardDayIndex),
                onFavorite: { dailyCardStore.toggleFavorite(card.id) },
                isFavorite: dailyCardStore.isFavorite(card.id)
            )
            .opacity(dailyCardStore.isFront ? 1 : 0)
            .rotation3DEffect(.degrees(dailyCardStore.transitionAngle - 180), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .padding(.horizontal, 24)
        .onTapGesture { dailyCardStore.flip() }
        .onLongPressGesture(minimumDuration: 0.5) {
            HapticManager.medium()
            shareManager.showShareOptions = true
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 20) {
            BottomBarButton(icon: "book.fill", label: dailyCardStore.appLanguage == "zh-Hans" ? "经文" : "Bible") {
                HapticManager.light()
                withAnimation { currentPage = .bible }
            }
            BottomBarButton(icon: "square.and.arrow.up", label: dailyCardStore.appLanguage == "zh-Hans" ? "分享" : "Share") {
                HapticManager.light()
                shareManager.showShareOptions = true
            }
            BottomBarButton(icon: "note.text", label: dailyCardStore.appLanguage == "zh-Hans" ? "笔记" : "Notes") {
                HapticManager.light()
                notesStore.isNoteEditorPresented = true
            }
            BottomBarButton(icon: "gearshape.fill", label: dailyCardStore.appLanguage == "zh-Hans" ? "设置" : "Settings") {
                HapticManager.light()
                withAnimation { currentPage = .settings }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Notes Expand Overlay
    private var notesExpandOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    notesStore.save()
                    withAnimation(Design.springAnim) { notesStore.isNoteEditorPresented = false }
                }

            if let card = dailyCardStore.currentCard {
                NoteEditorCard(
                    noteText: $notesStore.noteText,
                    card: card,
                    language: dailyCardStore.appLanguage,
                    onClose: {
                        notesStore.save()
                        withAnimation(Design.springAnim) { notesStore.isNoteEditorPresented = false }
                    }
                )
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.85).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Share Options Overlay
    private var shareOptionsOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { shareManager.showShareOptions = false }

            if let card = dailyCardStore.currentCard {
                ShareOptionsCard(
                    card: card,
                    language: dailyCardStore.appLanguage,
                    noteText: notesStore.noteText,
                    onSelect: { mode in
                        shareManager.showShareOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            performShare(mode: mode, card: card)
                        }
                    },
                    onClose: { shareManager.showShareOptions = false }
                )
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func performShare(mode: ShareManager.ShareMode, card: RevealCard) {
        let lang = dailyCardStore.appLanguage
        let shareText: String
        switch mode {
        case .verse:
            shareText = "\"\(card.verseText(language: lang))\"\n— \(card.reference)"
        case .reflection:
            shareText = "Reflect: \(card.questionText(language: lang))\n\nAction: \(card.actionText(language: lang))"
        case .note:
            shareText = notesStore.noteText.isEmpty
                ? "My reflection on \(card.reference)"
                : notesStore.noteText
        case .fullSet:
            shareText = "\"\(card.verseText(language: lang))\"\n— \(card.reference)\n\nReflect: \(card.questionText(language: lang))\n\nAction: \(card.actionText(language: lang))"
        }

        // Export as PNG image
        let renderer = ImageRenderer(content: shareCardImage(mode: mode, card: card, lang: lang))
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [image, shareText], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } else {
            // Fallback: share text only
            let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }

    @ViewBuilder
    private func shareCardImage(mode: ShareManager.ShareMode, card: RevealCard, lang: String) -> some View {
        VStack(spacing: 0) {
            switch mode {
            case .verse, .reflection, .fullSet:
                VStack(spacing: 12) {
                    if mode == .verse || mode == .fullSet {
                        VStack(spacing: 8) {
                            Text("Reveal Mashal")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Design.accent)
                            Text("\"\(card.verseText(language: lang))\"")
                                .font(.custom("Georgia", size: 16))
                                .foregroundColor(Color(hex: "2A2A2A"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                            Text(card.reference)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "4A4A4A"))
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "FAF7F2"))
                                .shadow(color: Color.black.opacity(0.1), radius: 10)
                        )
                    }
                    if mode == .reflection || mode == .fullSet {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle.fill").foregroundColor(Design.accent)
                                Text(lang == "zh-Hans" ? "反思" : "Reflect")
                                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "4A4A4A"))
                            }
                            Text(card.questionText(language: lang))
                                .font(.system(size: 13)).foregroundColor(Color(hex: "3A3A3A")).lineSpacing(4)
                            Divider()
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(Design.accent)
                                Text(lang == "zh-Hans" ? "行动" : "Action")
                                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "4A4A4A"))
                            }
                            Text(card.actionText(language: lang))
                                .font(.system(size: 13)).foregroundColor(Color(hex: "3A3A3A")).lineSpacing(4)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "FAF7F2"))
                                .shadow(color: Color.black.opacity(0.1), radius: 10)
                        )
                    }
                }
            case .note:
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.reference)
                        .font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent)
                    Text(notesStore.noteText.isEmpty ? (lang == "zh-Hans" ? "（暂无笔记）" : "(No notes yet)") : notesStore.noteText)
                        .font(.system(size: 14)).foregroundColor(Color(hex: "2A2A2A")).lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "FAF7F2"))
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                )
            }
            // App watermark
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill").font(.system(size: 10)).foregroundColor(Design.accent)
                Text("Reveal Mashal").font(.system(size: 10, weight: .medium)).foregroundColor(Design.accent.opacity(0.7))
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(hex: "FFFAE3"))
    }
}

// MARK: - Bottom Bar Button
struct BottomBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Design.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.7))
                            .shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3)
                    )
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isDark ? Color.white.opacity(0.6) : Color(hex: "6B6B6B"))
            }
        }
    }
}

// MARK: - Home Circle Button (top bar)
struct HomeCircleButton: View {
    let icon: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Design.accent)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.6))
                        .shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3)
                )
        }
    }
}

// MARK: - Card Front View
struct CardFrontView: View {
    let card: RevealCard
    let language: String
    let gradient: [Color]
    let onFavorite: () -> Void
    let isFavorite: Bool

    private var verseLabel: String { language == "zh-Hans" ? "今日经文" : "TODAY'S VERSE" }
    private var tapHint: String { language == "zh-Hans" ? "点击查看思考问题" : "Tap to reveal reflection" }

    var body: some View {
        VStack(spacing: 0) {
            // Header row: label + favorite
            HStack {
                Text(verseLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Design.accent)
                    .tracking(2)
                Spacer()
                FavoriteButton(isFavorite: isFavorite, onTap: onFavorite)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            Text("\"\(card.verseText(language: language))\"")
                .font(.custom("Georgia", size: 20))
                .foregroundColor(Color(hex: "2A2A2A"))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 24)

            Spacer()

            Text(card.reference)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4A4A4A").opacity(0.8))
                .padding(.bottom, 16)

            Text(tapHint)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(Color(hex: "9E9E9E"))
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Design.cardShadowColor, radius: 16, x: 0, y: 8)
        )
    }
}

// MARK: - Card Back View
struct CardBackView: View {
    let card: RevealCard
    let language: String
    let onFavorite: () -> Void
    let isFavorite: Bool

    private var titleLabel: String { language == "zh-Hans" ? "默想" : "REFLECTION" }
    private var reflectLabel: String { language == "zh-Hans" ? "反思" : "Reflect" }
    private var actionLabel: String { language == "zh-Hans" ? "行动" : "Action" }
    private var tapHint: String { language == "zh-Hans" ? "点击返回" : "Tap to return" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(titleLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Design.accent)
                        .tracking(2)
                    Spacer()
                    FavoriteButton(isFavorite: isFavorite, onTap: onFavorite)
                }
                .padding(.top, 24)

                Divider().background(Color.black.opacity(0.08)).padding(.top, 12).padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill").font(.system(size: 16)).foregroundColor(Design.accent)
                        Text(reflectLabel).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "4A4A4A"))
                    }
                    Text(card.questionText(language: language))
                        .font(.system(size: 15)).foregroundColor(Color(hex: "3A3A3A")).lineSpacing(5)
                }

                Spacer().frame(height: 24)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundColor(Design.accent)
                        Text(actionLabel).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "4A4A4A"))
                    }
                    Text(card.actionText(language: language))
                        .font(.system(size: 15)).foregroundColor(Color(hex: "3A3A3A")).lineSpacing(5)
                }

                Spacer().frame(height: 24)

                Text(tapHint)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Color(hex: "9E9E9E"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Design.cardRadius)
                .fill(Color(hex: "FAF7F2"))
                .shadow(color: Design.cardShadowColor, radius: 16, x: 0, y: 8)
        )
    }
}

// MARK: - Favorite Button
struct FavoriteButton: View {
    let isFavorite: Bool
    let onTap: () -> Void
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.4 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.0 }
            }
            onTap()
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isFavorite ? .yellow : Design.accent.opacity(0.5))
                .scaleEffect(scale)
        }
    }
}

// MARK: - Note Editor Card
struct NoteEditorCard: View {
    @Binding var noteText: String
    let card: RevealCard
    let language: String
    let onClose: () -> Void
    @FocusState private var isFocused: Bool
    @EnvironmentObject var dailyCardStore: DailyCardStore

    private var titleText: String { language == "zh-Hans" ? "我的感想" : "My Reflection" }
    private var hintText: String { language == "zh-Hans" ? "写下你的反思..." : "Write your reflection..." }
    private var autoSaveText: String { language == "zh-Hans" ? "自动保存" : "Auto-saves" }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = language == "zh-Hans" ? "yyyy年M月d日" : "MMMM d, yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(titleText).font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "2A2A2A"))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "9E9E9E"))
                }
            }

            Divider().padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.reference).font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent)
                Text(formattedDate).font(.system(size: 11, weight: .light)).foregroundColor(Color(hex: "9E9E9E"))
            }
            .padding(.bottom, 12)

            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text(hintText).font(.system(size: 15)).foregroundColor(Color(hex: "BFBFBF")).padding(.horizontal, 4).padding(.vertical, 8)
                }
                TextEditor(text: $noteText)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "2A2A2A"))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .onChange(of: noteText) { _ in
                        NotesStore.shared.save()
                    }
            }
            .frame(minHeight: 160)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "F5F2ED")).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1)))

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle").font(.system(size: 11))
                Text(autoSaveText).font(.system(size: 11, weight: .light))
            }
            .foregroundColor(Design.accent)
            .padding(.top, 8)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: Design.notesRadius).fill(Color(hex: "FAF7F2")).shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10))
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true } }
        .onDisappear { isFocused = false }
    }
}

// MARK: - Share Options Card
struct ShareOptionsCard: View {
    let card: RevealCard
    let language: String
    let noteText: String
    let onSelect: (ShareManager.ShareMode) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language == "zh-Hans" ? "分享" : "Share")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "2A2A2A"))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "9E9E9E"))
                }
            }
            .padding(20)

            Divider()

            VStack(spacing: 4) {
                ForEach(ShareManager.ShareMode.allCases, id: \.self) { mode in
                    Button(action: {
                        HapticManager.light()
                        onSelect(mode)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: mode.iconName).font(.system(size: 20)).foregroundColor(Design.accent)
                                .frame(width: 36, height: 36)
                                .background(Design.accent.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(language == "zh-Hans" ? mode.titleZH(lang: language) : mode.titleEN(lang: language))
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "2A2A2A"))
                                Text(language == "zh-Hans" ? mode.subtitleZH() : mode.subtitleEN())
                                    .font(.system(size: 12, weight: .light)).foregroundColor(Color(hex: "9E9E9E"))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(Color(hex: "D0D0D0"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(RoundedRectangle(cornerRadius: Design.notesRadius).fill(Color(hex: "FAF7F2")).shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10))
    }
}

// MARK: - Bible Passage View
struct BiblePassageView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @State private var passageText: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    BackCircleButton { withAnimation { currentPage = .home } }
                    Spacer()
                    Text(dailyCardStore.appLanguage == "zh-Hans" ? "经文" : "Full Passage")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                ScrollView {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Design.accent)
                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "加载中..." : "Loading...")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "9E9E9E"))
                        }
                        .padding(.top, 80)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundColor(Design.accent.opacity(0.5))
                            Text(error).font(.system(size: 14)).foregroundColor(Color(hex: "9E9E9E")).multilineTextAlignment(.center)
                        }
                        .padding(.top, 80)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(dailyCardStore.currentCard?.reference ?? "")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "2A2A2A"))
                                Spacer()
                                // Open in browser button
                                Button(action: openInBrowser) {
                                    Image(systemName: "safari").font(.system(size: 16)).foregroundColor(Design.accent)
                                }
                            }

                            Text(passageText)
                                .font(.custom("Georgia", size: 17))
                                .foregroundColor(Color(hex: "2A2A2A"))
                                .lineSpacing(8)
                                .textSelection(.enabled)

                            Divider().padding(.vertical, 8)

                            Text(dailyCardStore.currentCard?.questionText(language: dailyCardStore.appLanguage) ?? "")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "4A4A4A"))
                                .lineSpacing(5)

                            Spacer().frame(height: 8)

                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(Design.accent)
                                Text(dailyCardStore.currentCard?.actionText(language: dailyCardStore.appLanguage) ?? "")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Design.accent)
                            }
                        }
                        .padding(24)
                    }
                }
                .background(RoundedRectangle(cornerRadius: Design.cardRadius).fill(Color(hex: "FAF7F2")).shadow(color: Design.cardShadowColor, radius: 16, x: 0, y: 8))
                .padding(.horizontal, 24)
                .padding(.top, 20)

                BackToHomeButton { withAnimation { currentPage = .home } }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
            }
        }
        .onAppear { loadPassage() }
    }

    private func loadPassage() {
        guard let card = dailyCardStore.currentCard else { return }
        isLoading = true
        errorMessage = nil
        passageText = ""

        let lang = dailyCardStore.appLanguage
        Task {
            do {
                let text = try await BibleAPIService.fetchFullPassage(
                    book: card.book,
                    chapter: card.chapter,
                    verse: card.verse,
                    language: lang
                )
                await MainActor.run {
                    passageText = text
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Fallback: use the verse from our card JSON
                    passageText = card.verseText(language: lang)
                    errorMessage = nil
                    isLoading = false
                }
            }
        }
    }

    private func openInBrowser() {
        guard let card = dailyCardStore.currentCard else { return }
        let lang = dailyCardStore.appLanguage
        let urlString: String
        if lang == "zh-Hans" {
            // Open Chinese Bible API
            urlString = "https://bible.helloao.org/cn/\(card.book.lowercased())/\(card.chapter).html"
        } else {
            urlString = "https://bible.helloao.org/\(card.book.lowercased())/\(card.chapter).html"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Back Circle Button
struct BackCircleButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Design.accent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(isDark ? Color.white.opacity(0.1) : Color.white.opacity(0.6)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))
        }
    }
}

// MARK: - Back To Home Button
struct BackToHomeButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                Text("Back to Home")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(hex: "2A2A2A"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "FAF7F2")).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.08), lineWidth: 1)).shadow(color: Design.cardShadowColor, radius: 8))
        }
    }
}

// MARK: - Calendar View
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
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
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
                    BackCircleButton { withAnimation { currentPage = .home } }
                    Spacer()
                    Text("Scripture History")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                sectionTabs.padding(.horizontal, 24).padding(.top, 20)

                switch selectedSection {
                case .daily: dailySection
                case .favorites: favoritesSection
                case .notes: notesSection
                }
            }
        }
    }

    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(CalendarSection.allCases, id: \.self) { section in
                Button(action: { withAnimation { selectedSection = section } }) {
                    Text(dailyCardStore.appLanguage == "zh-Hans" ? section.titleZH(lang: "zh-Hans") : section.titleEN(lang: "en"))
                        .font(.system(size: 13, weight: selectedSection == section ? .bold : .medium))
                        .foregroundColor(selectedSection == section ? .white : Design.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(selectedSection == section ? Design.accent : Design.accent.opacity(0.1)))
                }
            }
        }
    }

    private var dailySection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { withAnimation { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth } }) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(Design.accent).frame(width: 40, height: 40)
                }
                Spacer()
                Text(monthTitle).font(.system(size: 17, weight: .semibold)).foregroundColor(.primary)
                Spacer()
                Button(action: { withAnimation { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth } }) {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundColor(Design.accent).frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
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
        .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 40)
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
                .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 40)
            }
        }
    }

    private var notesSection: some View {
        ScrollView {
            let noteText = UserDefaults.standard.string(forKey: "UserNoteText") ?? ""
            if noteText.isEmpty {
                emptyState(
                    icon: "note.text",
                    title: dailyCardStore.appLanguage == "zh-Hans" ? "暂无笔记" : "No Notes Yet",
                    subtitle: dailyCardStore.appLanguage == "zh-Hans" ? "写下你的第一篇反思" : "Write your first reflection"
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(dailyCardStore.currentCard?.reference ?? "")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent)
                    Text(noteText).font(.system(size: 15)).foregroundColor(Color(hex: "3A3A3A")).lineSpacing(5)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "FAF7F2")).shadow(color: Design.cardShadowColor, radius: 12))
            }
        }
        .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 40)
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
    let date: Date?
    private let calendar = Calendar.current
    private func hasScripture(for date: Date?) -> Bool {
        guard let date = date else { return false }
        let day = calendar.component(.day, from: date)
        return day >= 1 && day <= 31
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

// MARK: - Favorite Card Row
struct FavoriteCardRow: View {
    let card: RevealCard
    let language: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.reference)
                .font(.system(size: 12, weight: .medium)).foregroundColor(Design.accent)
            Text("\"\(card.verseText(language: language))\"")
                .font(.custom("Georgia", size: 14)).foregroundColor(Color(hex: "3A3A3A")).lineLimit(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "FAF7F2")).shadow(color: Design.cardShadowColor, radius: 8))
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @State private var notificationsEnabled = true
    @State private var reminderTime = Date()
    @State private var showAboutSources = false

    var body: some View {
        ZStack {
            AppBackground()
            VStack {
                HStack {
                    BackCircleButton { withAnimation { currentPage = .home } }
                    Spacer()
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                ScrollView {
                    VStack(spacing: 16) {
                        // Appearance
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "circle.lefthalf.filled").foregroundColor(Design.accent)
                                    Text(dailyCardStore.appLanguage == "zh-Hans" ? "外观" : "Appearance")
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                }
                                Picker("", selection: $themeManager.appearanceMode) {
                                    ForEach(ThemeManager.AppearanceMode.allCases, id: \.self) { mode in
                                        Text(mode.title(for: dailyCardStore.appLanguage)).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        // Language
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "globe").foregroundColor(Design.accent)
                                    Text(dailyCardStore.appLanguage == "zh-Hans" ? "语言" : "Language")
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                }
                                Menu {
                                    Button("English") { dailyCardStore.setLanguage("en") }
                                    Button("中文") { dailyCardStore.setLanguage("zh-Hans") }
                                } label: {
                                    HStack {
                                        Text(dailyCardStore.appLanguage == "zh-Hans" ? "中文" : "English")
                                            .foregroundColor(Design.accent)
                                        Spacer()
                                        Image(systemName: "chevron.down").foregroundColor(Design.accent.opacity(0.6))
                                    }
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1)))
                                }
                            }
                        }

                        // Daily Reminders
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell.fill").foregroundColor(Design.accent)
                                        Text(dailyCardStore.appLanguage == "zh-Hans" ? "每日提醒" : "Daily Reminders")
                                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $notificationsEnabled)
                                        .tint(Design.accent)
                                        .onChange(of: notificationsEnabled) { _, newValue in
                                            if newValue {
                                                let hour = Calendar.current.component(.hour, from: reminderTime)
                                                let minute = Calendar.current.component(.minute, from: reminderTime)
                                                Task {
                                                    await NotificationScheduler.scheduleDailyReminder(hour: hour, minute: minute, appLanguage: dailyCardStore.appLanguage)
                                                }
                                            } else {
                                                NotificationScheduler.cancelDailyReminder()
                                            }
                                        }
                                }
                                if notificationsEnabled {
                                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.compact)
                                        .tint(Design.accent)
                                        .foregroundColor(Design.accent)
                                        .onChange(of: reminderTime) { _, newValue in
                                            let hour = Calendar.current.component(.hour, from: newValue)
                                            let minute = Calendar.current.component(.minute, from: newValue)
                                            Task {
                                                await NotificationScheduler.scheduleDailyReminder(hour: hour, minute: minute, appLanguage: dailyCardStore.appLanguage)
                                            }
                                        }
                                }
                            }
                        }

                        // Contact Us
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill").foregroundColor(Design.accent)
                                    Text(dailyCardStore.appLanguage == "zh-Hans" ? "联系我们" : "Contact Us")
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                }
                                VStack(alignment: .leading, spacing: 10) {
                                    contactLink(icon: "envelope", text: "revealmashal@gmail.com", url: "mailto:revealmashal@gmail.com?subject=Reveal%20Mashal%20Feedback")
                                    contactLink(icon: "camera.fill", text: "@reveal_mashal", url: "https://www.instagram.com/reveal_mashal")
                                    contactLink(icon: "at", text: "X (Twitter)", url: "https://x.com/reveal_mashal?s=11")
                                    Text(dailyCardStore.appLanguage == "zh-Hans" ? "如有任何问题，请联系我们。" : "If you got any problems please contact us.")
                                        .font(.system(size: 12, weight: .light)).foregroundColor(Color(hex: "6B6B6B")).padding(.top, 2)
                                }
                            }
                        }

                        // About Bible Sources
                        SettingsCard {
                            Button(action: { showAboutSources = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill").foregroundColor(Design.accent)
                                    Text(dailyCardStore.appLanguage == "zh-Hans" ? "资料来源与版权声明" : "About Bible Sources")
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(Design.accent.opacity(0.6))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showAboutSources) {
            AboutBibleSourcesSheet(language: dailyCardStore.appLanguage)
        }
    }

    @ViewBuilder
    private func contactLink(icon: String, text: String, url: String) -> some View {
        if let u = URL(string: url) {
            Link(destination: u) {
                HStack(spacing: 8) {
                    Image(systemName: icon).foregroundColor(Design.accent)
                    Text(text).font(.system(size: 14)).foregroundColor(Design.accent)
                }
            }
        }
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1)))
    }
}

// MARK: - About Bible Sources Sheet
struct AboutBibleSourcesSheet: View {
    let language: String
    @Environment(\.dismiss) var dismiss
    private var isZH: Bool { language == "zh-Hans" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isZH { zhContent } else { enContent }
                }
                .padding(24)
            }
            .background(Color(hex: "FAF7F2"))
            .navigationTitle(isZH ? "资料来源与版权声明" : "Sources & Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Design.accent)
                }
            }
        }
    }

    private var enContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("English Bible Text")
            bodyText("Scripture quotations marked \"WEB\" are taken from the World English Bible (WEB).")
            bodyText("The World English Bible is a Public Domain translation of the Holy Bible and may be freely used, copied, and distributed.")
            linkText("Source: https://worldenglish.bible")
            Divider()
            sectionTitle("Chinese Bible Text")
            bodyText("Chinese Scripture quotations are taken from the Open Translation Bible (Chinese Edition).")
            bodyText("Copyright © Open Translation Bible Contributors.")
            bodyText("Licensed under the Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0).")
            linkText("Source: https://github.com/OpenTranslationBible/open-bible")
            linkText("License: https://creativecommons.org/licenses/by-sa/4.0/")
            Divider()
            sectionTitle("Attribution")
            bodyText("This application includes Bible text from the World English Bible (Public Domain) and the Open Translation Bible (CC BY-SA 4.0).")
            sectionTitle("Original Content")
            bodyText("All devotionals, reflections, study questions, user interface designs, graphics, logos, and other original content are created by Reveal and are not part of the Bible translations cited above.")
            sectionTitle("Copyright")
            bodyText("World English Bible (WEB): Public Domain.")
            bodyText("Open Translation Bible: Licensed under CC BY-SA 4.0.")
            bodyText("© Reveal. All original app content reserved by their respective owners.")
        }
    }

    private var zhContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("英文圣经")
            bodyText("本应用所引用的英文圣经经文，部分摘录自 World English Bible（WEB）。")
            bodyText("World English Bible（WEB）为公有领域（Public Domain）译本，可自由使用、复制、修改及传播，无需额外授权。")
            linkText("来源：https://worldenglish.bible")
            Divider()
            sectionTitle("中文圣经")
            bodyText("本应用所引用的中文圣经经文，部分摘录自 Open Translation Bible（开放翻译圣经）中文版。")
            bodyText("版权 © Open Translation Bible Contributors")
            bodyText("采用 Creative Commons Attribution-ShareAlike 4.0 International（CC BY-SA 4.0）许可协议发布。")
            bodyText("根据该许可协议，使用者可以分享及改编相关内容，但须注明出处，并以相同许可协议发布衍生作品。")
            linkText("来源：https://github.com/OpenTranslationBible/open-bible")
            linkText("许可协议：https://creativecommons.org/licenses/by-sa/4.0/")
            Divider()
            sectionTitle("版权归属")
            bodyText("本应用包含来自以下译本的圣经内容：")
            bodyText("• World English Bible（WEB）— 公有领域（Public Domain）")
            bodyText("• Open Translation Bible 中文版 — CC BY-SA 4.0")
            bodyText("相关版权及许可归原版权所有者及贡献者所有。")
            Divider()
            sectionTitle("原创内容")
            bodyText("本应用中的灵修内容、反思问题、学习笔记、界面设计、图标、标识、插图及其他原创内容，均由 Reveal 团队制作或依法使用，不属于上述圣经译本内容。")
            Divider()
            sectionTitle("免责声明")
            bodyText("本应用旨在提供圣经阅读、学习与灵修辅助服务。圣经经文版权归其各自译本及授权方所有。")
            bodyText("如发现版权归属或引用信息有误，请联系我们进行更正。")
            Divider()
            sectionTitle("版权所有")
            bodyText("World English Bible（WEB）：Public Domain")
            bodyText("Open Translation Bible：CC BY-SA 4.0")
            bodyText("© Reveal. 应用原创内容版权所有。")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "2A2A2A")).padding(.top, 8)
    }
    private func bodyText(_ text: String) -> some View {
        Text(text).font(.system(size: 14)).foregroundColor(Color(hex: "4A4A4A")).lineSpacing(4)
    }
    private func linkText(_ text: String) -> some View {
        Text(text).font(.system(size: 13)).foregroundColor(Design.accent)
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @State private var cardFlipped = false
    @State private var rotation: Double = 0

    private var lang: String { dailyCardStore.appLanguage }
    private var currentCard: RevealCard? { dailyCardStore.cardForOnboarding(at: 0) }

    private let stepTextsEN = [
        "Here is the verse of the day. Tap the card to reveal reflection.",
        "Tap to see the reflection question and action step.",
        "Tap the Bible icon to read the full passage.",
        "Tap Calendar to revisit all verses you've studied.",
        "Tap Note to write your personal reflection. It saves automatically.",
        "Start your journey now!"
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { withAnimation { showOnboarding = false } }
                        .foregroundColor(Design.accent.opacity(0.6))
                        .padding()
                }

                Spacer()

                if let card = currentCard {
                    OnboardingCardDemo(
                        card: card,
                        cardFlipped: $cardFlipped,
                        rotation: $rotation,
                        lang: lang
                    )
                }

                TutorialBubble(text: stepTextsEN[0])
                    .padding(.bottom, 44)

                HStack(spacing: 20) {
                    Button("Get Started") {
                        withAnimation { showOnboarding = false }
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Card Demo
struct OnboardingCardDemo: View {
    let card: RevealCard
    @Binding var cardFlipped: Bool
    @Binding var rotation: Double
    let lang: String
    @State private var cardDayIndex: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Bible button with arrow pointing down to it
                ZStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Design.accent)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.7)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))

                    // Arrow below the Bible button
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Design.accent)
                        .offset(y: 36)
                        .opacity(0.8)
                }
                Spacer()
                // Calendar button
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Design.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.7)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)

            Spacer()

            ZStack {
                CardBackView(card: card, language: lang, onFavorite: {}, isFavorite: false)
                    .opacity(cardFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.5)

                CardFrontView(
                    card: card, language: lang,
                    gradient: Design.gradientForDay(cardDayIndex),
                    onFavorite: {}, isFavorite: false
                )
                .opacity(cardFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(rotation - 180), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .padding(.horizontal, 24)
            .onTapGesture {
                withAnimation(Design.springAnim) {
                    cardFlipped.toggle()
                    rotation += 180
                }
            }

            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Design.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.7)).shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3))

                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Design.accent)
                    .offset(x: -44, y: -30)
                    .opacity(0.8)
            }
            .padding(.top, 16)

            Spacer()
        }
        .opacity(0.9)
    }
}

// MARK: - Tutorial Bubble
struct TutorialBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color(hex: "2A2A2A"))
            .multilineTextAlignment(.center)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "FAF7F2")).shadow(color: Color.black.opacity(0.12), radius: 10))
            .padding(.horizontal, 32)
    }
}

// MARK: - Onboarding Button Styles
struct OnboardingGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 28).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.2), lineWidth: 1)))
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .semibold))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 36).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 22).fill(Design.accent))
            .foregroundColor(.white)
            .font(.system(size: 15, weight: .bold))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView()
}
