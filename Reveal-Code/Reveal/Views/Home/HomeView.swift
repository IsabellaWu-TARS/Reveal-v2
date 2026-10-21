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
    @Environment(\.colorScheme) private var colorScheme
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

            // P22: 4 round corner buttons are ~10pt bigger than the
            // design-wide `Design.cornerButtonSize` so they read more
            // prominently on the home screen. The SF Symbol scales
            // proportionally (18 → 22) so the icon stays centred
            // visually. The top/bottom bar height follows the same
            // bump so the buttons aren't clipped.
            let homeCornerButtonSize: CGFloat = Design.cornerButtonSize + 10  // 54 / 58
            let _: CGFloat  = 22

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
                .frame(width: cornerBarWidth, height: homeCornerButtonSize)
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
                        .foregroundColor(Design.accent) // P19: matching green so the centre Notes pill matches the four corner icons.
                        .frame(width: noteW, height: noteH)
                        .background(
                            // P21 dark-mode branch: same translucent white
                            // (`white.opacity(0.1)`) used by ScripturePage's
                            // BackCircleButton, so the pill stays in the
                            // same visual family as the 4 corner chips in
                            // dark mode.
                            Capsule()
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.1)
                                      : Design.paperChipFill)
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
                .frame(width: cornerBarWidth, height: max(noteH, homeCornerButtonSize))
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
                // The note editor is presented as a sheet (see .sheet below):
                // inside the page ZStack it inherited the page's mis-sized
                // coordinate space and ran off the right edge.

                // P20: back to an inline overlay, now that the page ZStack
                // is the right width. A full-screen cover paints its own
                // backdrop, which read as "the whole app goes black" behind
                // the share card; this draws the card straight over the live
                // home screen with no dim.
                if shareManager.showShareOptions {
                    ZStack {
                        Color.clear
                            .contentShape(Rectangle())
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
                            .frame(width: max(screenW - Design.horizontalPadding * 2, 0))
                            .frame(maxHeight: screenH * 0.78)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(width: screenW, height: screenH)
                    .zIndex(2)
                }
            }
        }
        .onAppear {
            cardDayIndex = Calendar.current.component(.day, from: Date())
            dailyCardStore.markTodayViewed()
        }
        // The note editor used to be a hand-rolled overlay inside the page
        // ZStack; that ZStack's coordinate space did not match the screen, so
        // the card hung off the right edge. A sheet is anchored to the window,
        // so the width and the keyboard insets are always correct.
        .fullScreenCover(isPresented: $notesStore.isNoteEditorPresented, onDismiss: { notesStore.save() }) {
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { notesStore.isNoteEditorPresented = false }

                if let card = dailyCardStore.currentCard {
                    NoteEditorCard(
                        noteText: $notesStore.noteText,
                        card: card,
                        language: dailyCardStore.appLanguage,
                        onClose: { notesStore.isNoteEditorPresented = false }
                    )
                    .padding(.horizontal, Design.horizontalPadding)
                    .frame(maxWidth: .infinity)
                }
            }
            .presentationBackground(.clear)
        }
    }

    // MARK: - Outer Action Button (P9)
    // Reusable round icon button that lives OUTSIDE the card. Same visual
    // language as the corner buttons so the screen reads as one consistent
    // set of controls, just repositioned so they never fight with the card
    // for touch.
    //
    // P19: foreground flipped from `Design.paperInk` to `Design.accent`
    // so the SF Symbols (`book.fill` / `calendar` / `square.and.arrow.up`
    // / `gearshape.fill`) render in the brand green on every HomeScreen
    // corner button. Background stays cream — only the icon recolours.
    //
    // P21: dark-mode background swap. In light mode the button keeps the
    // original `Design.paperChipFill` cream tint; in dark mode it switches
    // to the same translucent white (`white.opacity(0.1)`) used by
    // ScripturePage's `BackCircleButton`. Matching the back-chevron's
    // visual weight keeps every HomeScreen control on the same design
    // family as the rest of the app.
    private func outerActionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium)) // P22: icon scales with the larger button (18 → 22).
                .foregroundColor(Design.accent)
                .frame(width: Design.cornerButtonSize + 10, height: Design.cornerButtonSize + 10)
                .background(
                    Circle()
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.1)
                              : Design.paperChipFill)
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

        // What goes into the share sheet depends on the option:
        //   verse      → the card's front face as a PNG
        //   reflection → the card's back face as a PNG
        //   note       → plain text
        //   full set   → both faces + the text (verse, reflection, note)
        let style = CardStyle.forCardId(card.id)
        var items: [Any] = []

        switch mode {
        case .verse:
            if let front = renderCardPNG(front: true, card: card, style: style, lang: lang) {
                items.append(front)
            }
        case .reflection:
            if let back = renderCardPNG(front: false, card: card, style: style, lang: lang) {
                items.append(back)
            }
        case .note:
            items.append(shareText)
        case .fullSet:
            if let front = renderCardPNG(front: true, card: card, style: style, lang: lang) {
                items.append(front)
            }
            if let back = renderCardPNG(front: false, card: card, style: style, lang: lang) {
                items.append(back)
            }
            items.append(shareText)
        }

        // If rendering failed for any reason, still share something useful.
        if items.isEmpty { items = [shareText] }
        presentShareSheet(items: items)
    }

    /// Renders the real card view (the same one on screen) to a PNG, with the
    /// favourite button hidden so the export looks like the artwork, not a
    /// screenshot of the UI.
    @MainActor
    private func renderCardPNG(front: Bool, card: RevealCard, style: CardStyle, lang: String) -> UIImage? {
        let content = Group {
            if front {
                CardFrontView(card: card, language: lang, style: style,
                              onFavorite: {}, isFavorite: false, showsFavoriteButton: false)
            } else {
                CardBackView(card: card, language: lang, style: style,
                             onFavorite: {}, isFavorite: false,
                             showsFavoriteButton: false, showsReturnHint: false)
            }
        }
        // Same 0.63 aspect as the on-screen card, at 3x for a crisp export.
        .frame(width: 360, height: 572)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 3.0
        renderer.isOpaque = false
        return renderer.uiImage
    }

    /// Presents from the top-most view controller. While the share overlay was
    /// an inline view the root controller was free; now that the overlay is a
    /// full-screen cover, presenting from the root would fail with
    /// "already presenting", so walk down to whatever is actually on top.
    private func presentShareSheet(items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              var top = scene.windows.first?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        top.present(activityVC, animated: true)
    }

}
