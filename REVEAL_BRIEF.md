# Reveal — Handoff Brief

**App:** Reveal — daily one-card devotion (one Bible card per day, flip to reflect).
**Canonical code:** `~/Desktop/💡Startupss/Reveal Mashal/Reveal-Code/`
(ignore `Reveal_Mashal/` — older modular fork, last touched July)
**Stack:** SwiftUI, iOS 26.0 deployment target, Xcode 27.1, scheme `Reveal`, bundle id `com.isabellawu.Vibe` (legacy name), display name `Reveal`.
**Git:** `main`, 2 squashed commits, no remote, still uncommitted (the split + service below are working-tree changes).

## Source — split out of the old single file

`Reveal/VibeApp.swift` was 2,961 lines. It is now 25 files, largest 466 lines:

```
RevealApp.swift                   73   @main, ContentView, AppPage, #Preview
Design/           CardStyle 198 · Design 178 · Shapes 63
Models/           BookNames 43 · RevealCard 52 · SeededRNG 19
Stores/           DailyCardStore 185 · NotesStore 77 · ShareManager 68 · ThemeManager 51
Views/Home/       HomeView 466 · CardBackView 118 · CardFrontView 98 · NoteEditorCard 83 · ShareOptionsCard 63
Views/            Bible/BiblePassageView 279 · Calendar/CalendarView 265 · Calendar/FavoriteCardRow 26
                  Settings/SettingsView 206 · Settings/AboutBibleSourcesSheet 105
                  Onboarding/OnboardingView 203 · SplashView 82 · Components/Buttons 128
Services          BibleAPIService 310 · NotificationScheduler 202
```

Split was mechanical (declaration boundaries, extensions kept with their type, no behaviour
change) and the same build + tests passed before and after. `HomeView` (466) is the next
thing worth breaking up — the card preview/share closure is ~200 of those lines.

## Structure

`VibeApp` → `ContentView` → splash → onboarding (first launch) → 4 pages: `home` / `bible` / `calendar` / `settings`.
- `DailyCardStore` (`@MainActor`): seeds `SeededRNG` from `yyyy-MM-dd` → same date, same card; tracks `seenCardIds`, `favoriteIds`, `viewedDates` in UserDefaults.
- `NotesStore`, `ShareManager`, `ThemeManager`.
- `CardFrontView` / `CardBackView` 3D flip; `CardStyle` = 24 vertical gradients.
- `BiblePassageView` = card text (offline) + the full chapter (API) with the card's verse highlighted.

## Content

`Reveal/Resources/RevealCards_bilingual.json` — **314 cards, 55 books**, EN + zh-Hans, verse
text embedded (WEB / 和合本). Regenerate with `repair_cards_bilingual.py` (source of truth:
`Card Content/BibleVerses.txt` + `Card Content/中文圣经verses.txt`).

The old file had 324 records: 38 with `book: ""` / `id: "-1-1"` / shifted fields, plus 10
phantom duplicates — but the damage was wider than the 38: **168 cards carried a Chinese
verse belonging to a different reference** (the Chinese column had drifted by one inside each
book, e.g. `2-samuel-7-22` showed 2 Samuel 22:31's Chinese text). All rebuilt from source;
ids preserved (`genesis-1-1`, `psalm-27-1`, …) so favourites/notes still resolve.

## Bible API — working

`Reveal/BibleAPIService.swift` (actor): `chapter(book:chapter:language:)` →
`GET https://bible.helloao.org/api/{eng_web|cmn_cu1}/{USFM}/{chapter}.json`.
No key, no Info.plist entry (the plist is generated). `URLCache` + in-actor memo.
`Data/BIBLE_API_GUIDE.md` rewritten against the live API (the documented `/api/verse` is a 404).

Non-obvious payload details that broke the first decoder:
- content items are `String` **or** `{"text","poem"}` **or** `{"noteId": N}` (footnote markers
  in 1 Corinthians 12 and friends → `The data couldn't be read because it is missing.`)
- `heading` / `hebrew_subtitle` blocks belong to the verse that follows them.

## Build & test

```
xcodebuild -project Reveal.xcodeproj -scheme Reveal -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build            # BUILD SUCCEEDED
xcodebuild test -project Reveal.xcodeproj -scheme Reveal \
  -destination 'platform=iOS Simulator,id=F026A111-CDA9-4E08-818D-47A4BED7C896' \
  CODE_SIGNING_ALLOWED=NO                  # TEST SUCCEEDED (5 unit + 2 UI)
```

Simulator works: CoreSimulator 1171.7 vs 1174.9.2 sorted itself out on the first `simctl`
run (it drops the stale service); no `sudo installer` was needed. Device: **iPhone 17**
`F026A111-CDA9-4E08-818D-47A4BED7C896` (iOS 27.0 runtime only).

Test targets were pointing at the old target name — fixed `TEST_TARGET_NAME = Reveal` and
`@testable import Reveal`.

## Fixed this session

1. Card data rebuilt from source (314 cards, unique ids, bilingual pairing verified).
2. `BibleAPIService` + wired `BiblePassageView`: chapter list, highlight, retry, offline floor,
   auto-scroll to the card's verse, bottom fade.
3. Simulator + UI-test pipeline; `RevealCaptureTests` screenshots the passage screen in EN/ZH.
4. `CardStyle.forCardId` used `String.hashValue` (randomised per process) → gradients changed
   every launch; now FNV-1a.
5. Double-wrapped quotes on direct-speech verses (`““…””`).
6. Chinese mode showed English book names → `BookNames` map + `card.referenceText(language:)`
   across card, passage, calendar, favourites, notes and share text.
7. `Dictionary(uniqueKeysWithValues:)` on card ids → would trap on duplicate ids; now
   `uniquingKeysWith`.
8. Unit tests guard the data (count, ids, no verse-in-question, every book resolves to USFM)
   and the decoder (footnote/poem fixture).

## Open

- Chinese text credited in the About sheet as Open Translation Bible (CC BY-SA), while the
  bundled text is 和合本 and the fetched chapter is `cmn_cu1` (helloao reports **public
  domain**). Reconcile the credit with what actually ships.
- `HomeView` is 466 lines — the next split target.
- No full-Bible browser (book → chapter picker); `BibleAPIService` already supports any
  book/chapter, so it is a UI-only addition.
- Decide what to commit: ~45 dirty entries, including the whole `Vibe.xcodeproj`/`Vibe/`
  deletion from the rename.
