//
//  HomeView.swift
//  Reveal
//
//  Split out of the original single-file VibeApp.swift.
//

import SwiftUI
import Combine
import UIKit

struct HomeView: View {
    @Binding var currentPage: AppPage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var dailyCardStore: DailyCardStore
    @EnvironmentObject var shareManager: ShareManager
    @StateObject private var notesStore = NotesStore.shared
    @State private var cardDayIndex: Int = 0

    var body: some View {
        GeometryReader { geo in
            let screenW = geo.size.width
            let screenH = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBot = geo.safeAreaInsets.bottom

            let cardW = screenW * 0.82
            let cardH = screenH * 0.60
            // BUG FIX (P5): noteW used to be 34% of the screen, which on
            // 17 Pro Max (430pt+) pushed the "Notes" pill wider than the
            // gap left after Share + Settings icons, hiding them off-screen.
            // We now use a fixed comfortable width and rely on GeometryReader
            // spacers to centre it.
            let noteW: CGFloat = Design.isLargeScreen ? 150 : 130
            let noteH: CGFloat = Design.noteButtonHeight

            // P11 layout maths. We anchor everything to the actual screen
            // size so the buttons are guaranteed to be in screen corners
            // regardless of any other ZStack children.
            //
            //  • Card        : 82% × 60%, centred.
            //  • Top bar     : top edge of screen, ~safeTop+12pt down.
            //  • Bottom bar  : bottom edge of screen, ~safeBot+24pt up.
            //
            // We use .position() with absolute screen coordinates instead of
            // relying on padding so the card can never "push" the bars into
            // itself (which is what caused the occlusion bug).

            let topBarY:    CGFloat = safeTop + 36   // centre-Y of top buttons
            let bottomBarY: CGFloat = screenH - safeBot - 56  // centre-Y of bottom buttons
            // ── P12: Frame layout ──────────────────────────────────────────
            // The 4 corner buttons used to be anchored to the absolute screen
            // edges (HStack with Spacer() + tiny sidePad). On wider phones
            // (Plus / Max) that flung them past the card's vertical edges so
            // they no longer read as a "frame around the card" — and on
            // extreme aspect ratios they could even slip off-screen.
            //
            // We now pin the outer buttons to the card's own vertical edges:
            //   • Top bar    : width == cardW  → Bible & Calendar sit above
            //                                  the card's top-left/top-right
            //                                  corners.
            //   • Bottom bar : width == cardW  → Share & Settings sit below
            //                                  the card's bottom-left/
            //                                  bottom-right corners; the
            //                                  "Notes" pill stays in the
            //                                  exact horizontal centre
            //                                  (between two Spacers).
            // The visual reads as one balanced rectangular frame around the
            // card, regardless of device width.
            let cornerBarWidth: CGFloat = cardW

            ZStack {
                AppBackground()

                // ── Top bar — fixed at screen top, never overlaps card ──
                // Width == cardW so the two buttons sit directly above the
                // card's top corners (no more flung-out-to-the-edge look).
                HStack {
                    outerActionButton(icon: "book.fill") {
                        HapticManager.light()
                        withAnimation { currentPage = .bible }
                    }
                    Spacer()
                    outerActionButton(icon: "calendar") {
                        HapticManager.light()
                        withAnimation { currentPage = .calendar }
                    }
                }
                .frame(width: cornerBarWidth, height: Design.cornerButtonSize)
                .position(x: screenW / 2, y: topBarY)

                // ── Bottom bar — fixed at screen bottom, never overlaps card ──
                // Width == cardW so Share & Settings sit directly below the
                // card's bottom corners. "Notes" stays in the horizontal
                // centre because the two Spacers are equal.
                HStack(alignment: .center, spacing: 0) {
                    // Share — left
                    outerActionButton(icon: "square.and.arrow.up") {
                        HapticManager.light()
                        shareManager.showShareOptions = true
                    }

                    Spacer()

                    // Notes pill — center
                    Button(action: {
                        HapticManager.light()
                        if let card = dailyCardStore.currentCard {
                            _ = notesStore.loadNote(for: card.id)
                        }
                        notesStore.isNoteEditorPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.system(size: 14, weight: .semibold))
                            Text(dailyCardStore.appLanguage == "zh-Hans" ? "笔记" : "Notes")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Design.paperInk)
                        .frame(width: noteW, height: noteH)
                        .background(
                            Capsule()
                                .fill(Design.paperChipFill)
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1)
                                )
                                .shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3)
                        )
                    }

                    Spacer()

                    // Settings — right
                    outerActionButton(icon: "gearshape.fill") {
                        HapticManager.light()
                        withAnimation { currentPage = .settings }
                    }
                }
                .frame(width: cornerBarWidth, height: max(noteH, Design.cornerButtonSize))
                .position(x: screenW / 2, y: bottomBarY)

                // Card – centred between the two bars. The bars are at fixed
                // y-positions so they cannot overlap the card, and the card
                // height (60% of screen) leaves ~20% above and below empty.
                if let card = dailyCardStore.currentCard {
                    cardContent(card: card)
                        .frame(width: cardW, height: cardH)
                        .position(x: screenW / 2, y: screenH / 2)
                } else {
                    ProgressView()
                        .frame(width: cardW, height: cardH)
                        .position(x: screenW / 2, y: screenH / 2)
                }

                // ── Overlays (above everything) ─────────────────────────────
                if notesStore.isNoteEditorPresented {
                    notesExpandOverlay
                }

                if shareManager.showShareOptions {
                    shareOptionsOverlay
                }
            }
        }
        .onAppear {
            cardDayIndex = Calendar.current.component(.day, from: Date())
            dailyCardStore.markTodayViewed()
        }
    }

    // MARK: - Outer Action Button (P9)
    // Reusable round icon button that lives OUTSIDE the card. Same visual
    // language as the corner buttons so the screen reads as one consistent
    // set of controls, just repositioned so they never fight with the card
    // for touch.
    private func outerActionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Design.paperInk)
                .frame(width: Design.cornerButtonSize, height: Design.cornerButtonSize)
                .background(
                    Circle()
                        .fill(Design.paperChipFill)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: Design.cardShadowColor, radius: 6, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card Content
    @ViewBuilder
    private func cardContent(card: RevealCard) -> some View {
        // Pick a gradient deterministically from the card id (not the
        // calendar date). Two consequences:
        //   • Each card gets its own colour, so flipping through the
        //     library shows visual variety — never "one colour for
        //     the whole day".
        //   • The same card id always picks the same colour, so the
        //     gradient never jitters when a card re-renders.
        // The front and the back share this `style`, so the flip
        // never changes the colour either.
        let style = CardStyle.forCardId(card.id)
        ZStack {
            // Back side — pre-rotated 180° so when the parent ZStack
            // is rotated to 180° the back face is now facing the
            // user. `.opacity` is what swaps which side is visible
            // (SwiftUI runs both faces on the same layer when
            // compositingGroup() is applied to the parent ZStack).
            CardBackView(
                card: card,
                language: dailyCardStore.appLanguage,
                style: style,
                onFavorite: { dailyCardStore.toggleFavorite(card.id) },
                isFavorite: dailyCardStore.isFavorite(card.id)
            )
            .opacity(dailyCardStore.isFront ? 0 : 1)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))

            // Front side — no individual rotation, the parent ZStack
            // does the 3D transform.
            CardFrontView(
                card: card,
                language: dailyCardStore.appLanguage,
                style: style,
                onFavorite: { dailyCardStore.toggleFavorite(card.id) },
                isFavorite: dailyCardStore.isFavorite(card.id)
            )
            .opacity(dailyCardStore.isFront ? 1 : 0)
        }
        // P17 (per user report): card flip was clipped during the
        // 3D rotation — visible "out of frame" / mirrored text
        // because (a) each face had its own rotation3DEffect so
        // SwiftUI composited two separate layers, and (b) the
        // `.clipShape` ran AFTER the rotation and clipped the
        // perspective overflow. Fix: a single `compositingGroup()`
        // merges both faces into one offscreen layer so the
        // perspective transform applies to the merged card. The
        // `.rotation3DEffect` on the parent ZStack is the only one
        // in the chain. We also drop the post-rotation `.clipShape`
        // — corner radius is now applied at the face level so it
        // does not interfere with the 3D transform.
        .compositingGroup()
        .rotation3DEffect(
            .degrees(dailyCardStore.transitionAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .contentShape(Rectangle())
        .onTapGesture { dailyCardStore.flip() }
        .onLongPressGesture(minimumDuration: 0.5) {
            HapticManager.medium()
            shareManager.showShareOptions = true
        }
    }

    // MARK: - Notes Expand Overlay
    // P12 fix: the NoteEditorCard used to render at its intrinsic height
    // (≈380–420pt), and when the iOS keyboard popped up it pushed content
    // past the top safe area / clipped under the status bar. We now wrap
    // the card in a GeometryReader and cap it to 62% of the visible
    // height, so:
    //   • on small phones (SE / 13 mini) it never overflows the screen,
    //   • when the keyboard rises, the card shrinks to fit instead of
    //     clipping, and
    //   • the visual is a touch smaller overall, as requested.
    private var notesExpandOverlay: some View {
        GeometryReader { geo in
            let capH = geo.size.height * 0.62
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
                    .frame(maxHeight: capH)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .scale(scale: 0.85).combined(with: .opacity)
                    ))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Share Options Overlay
    // P14 fix: same pattern as P12 Notes fix. ShareOptionsCard's intrinsic
    // height (≈327pt) could overflow on compact phones (e.g. 13 mini, SE).
    // We cap it to 62% of the visible height so it never clips off-screen.
    //
    // P14b fix (user feedback: "右边参照左边离屏幕的距离"): on some screens
    // the card was hugging / overflowing the right edge. The earlier
    // .frame(maxWidth: capW).frame(maxWidth: .infinity, alignment: .center)
    // trick wasn't enough on every device, and a single
    // .padding(.horizontal, sideMargin) could still drift if the ZStack
    // alignment above it tried to absorb the padding. We now belt-and-
    // brace it with an explicit HStack { Spacer; card; Spacer } so SwiftUI
    // is forced to split the remaining width into two EQUAL halves.
    private var shareOptionsOverlay: some View {
        GeometryReader { geo in
            let capH = geo.size.height * 0.62
            let capW = geo.size.width * 0.88
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { shareManager.showShareOptions = false }

                if let card = dailyCardStore.currentCard {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
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
                        .frame(maxWidth: capW)
                        .frame(maxHeight: capH)
                        Spacer(minLength: 0)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func performShare(mode: ShareManager.ShareMode, card: RevealCard) {
        let lang = dailyCardStore.appLanguage
        let shareText: String
        switch mode {
        case .verse:
            shareText = "\"\(card.verseText(language: lang))\"\n— \(card.referenceText(language: lang))"
        case .reflection:
            shareText = "Reflect: \(card.questionText(language: lang))\n\nAction: \(card.actionText(language: lang))"
        case .note:
            shareText = notesStore.noteText.isEmpty
                ? "My reflection on \(card.referenceText(language: lang))"
                : notesStore.noteText
        case .fullSet:
            shareText = "\"\(card.verseText(language: lang))\"\n— \(card.referenceText(language: lang))\n\nReflect: \(card.questionText(language: lang))\n\nAction: \(card.actionText(language: lang))"
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
                            Text(card.referenceText(language: lang))
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
                    Text(card.referenceText(language: lang))
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
