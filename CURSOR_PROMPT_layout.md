# Cursor prompt — fix the off-screen layout (Calendar + Settings)

Paste this into Cursor's chat with the workspace open at
`~/Desktop/💡Startupss/Reveal Mashal/Reveal-Code`.

---

Fix three layout defects in this SwiftUI app. I audited the running build on an
**iPhone 17 simulator (402 × 874 pt, iOS 27, dark mode)** and pulled the real
accessibility frames; the numbers below are measured, not guessed. Do not restructure
the app — this is a layout-only pass. Keep the existing design tokens
(`Design.accent`, `Design.horizontalPadding`, `Design.cardRadius`).

## 1. `Reveal/Views/Calendar/CalendarView.swift` — the whole page is 48 pt too wide and shifted left

Measured frames on the Calendar page:

- header back button: `x = 0, width = 44` → expected `x = 24` (`Design.horizontalPadding`)
- `sectionTabs` pills: `Daily` at `x = 0`, `Favorites` at `x = 72.3`, `Notes` at `x = 169`
  → the `Daily` pill's left edge is cut flat by the screen edge on all three tabs
- the month `ScrollView`: `origin x = -24, width = 450` on a **402 pt wide** screen
- the cream month card therefore spans `0…402` instead of `24…378`, so its left rounded
  corner is clipped by the screen edge while its right edge looks correct

So the page content is exactly `402 + 2×24 = 450` pt wide and gets centred in the ZStack,
which puts its origin at `x = -24`. The vertical `ScrollView` is sizing itself to its
*content* (the padded `VStack` inside `dailySection`) instead of to the screen. Find what
lets that width escape and constrain it — e.g. give the root `VStack`/`ScrollView`
`.frame(maxWidth: .infinity)` (and check `dailySection`'s inner `.padding(.horizontal,
Design.horizontalPadding)` is not the only width constraint). After the fix, every element
on the page must start at `x = 24` and end at `x = 378`.

## 2. Same file — the weekday header renders 5 of 7 letters and is misaligned

`CalendarView.swift:149`:

```swift
ForEach(weekdays, id: \.self) { w in
    Text(w)...
}
```

with weekday `["S","M","T","W","T","F","S"]`. `id: \.self` gives **duplicate ids**
(`T` twice, `S` twice), so SwiftUI renders only `S M T W F`. Measured: the header has 5
`StaticText`s while the date grid has 7 columns, so from column 5 on the labels no longer
line up (1 Oct 2026 is a Thursday and sits in column 5, under the letter `F`).

Fix: iterate indices, not letters — `ForEach(Array(weekdays.enumerated()), id: \.offset)`
— and make sure seven equal-width cells are laid out (e.g. a 7-column `LazyVGrid` with
identical `GridItem` config for the header and the dates, or fold the letters into the same
grid as a header row).

## 3. `Reveal/Views/Settings/SettingsView.swift` — reminder time chip overflows its card

In the “Daily Reminders” `SettingsCard` (`~line 100–138`) the compact
`DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)` is wider
than the card's content width, so the `20:25` chip is clipped by the card's right edge.
Constrain it inside the card (trailing-aligned `.frame(maxWidth: .infinity,
alignment: .trailing)` with the card's inner padding respected) — do not let it clip.

## How to verify

```
xcodebuild -project Reveal.xcodeproj -scheme Reveal \
  -destination 'generic/platform=iOS' -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

Must print `BUILD SUCCEEDED`, and these must keep passing:

```
xcodebuild test -project Reveal.xcodeproj -scheme Reveal \
  -destination 'platform=iOS Simulator,id=F026A111-CDA9-4E08-818D-47A4BED7C896' \
  -only-testing:RevealTests -only-testing:RevealUITests/LayoutAuditTests \
  CODE_SIGNING_ALLOWED=NO
```

`LayoutAuditTests` walks all four pages and attaches a screenshot of each — use it to
confirm the pills and the month card now sit at the 24 pt margin, and that all seven
weekday letters are visible.

Do not edit `RevealCards_bilingual.json`, `BibleAPIService.swift` or `Stores/` — this task
is layout only.
