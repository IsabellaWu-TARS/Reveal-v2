# Bible API — how it actually works

The app reads **whole chapters** from [bible.helloao.org](https://bible.helloao.org) through
`Reveal/BibleAPIService.swift`. This file documents the endpoint that exists, not the one
this guide used to describe.

> The old version of this page documented
> `GET /api/verse?translation=KJV&book=John&chapter=3&verse=16`.
> That path returns **HTTP 404** (a 20 KB HTML page, so a status-blind check looks "green").
> It never worked. Do not restore it.

---

## 1. No configuration, no key, no Info.plist entry

helloao is open and needs no credentials. There are **no `BIBLE_API_*` keys** in this project,
and `Info.plist` is generated (`GENERATE_INFOPLIST_FILE = YES`), so a plist edit would be
overwritten anyway. Plain HTTPS GETs — no ATS exception required.

Verified 2026-10-19 against the live service:

| Call | Result |
| --- | --- |
| `GET https://bible.helloao.org/api/eng_web/JHN/3.json` | 200 `application/json` |
| `GET https://bible.helloao.org/api/cmn_cu1/JHN/3.json` | 200 `application/json` |
| `GET https://bible.helloao.org/api/eng_web/books.json` | 200 — 66 books + apocrypha, USFM ids |

## 2. Endpoint shape

```
GET https://bible.helloao.org/api/{translationId}/{USFM_BOOK}/{chapter}.json
```

- **translationId** — `eng_web` (World English Bible) for English, `cmn_cu1`
  (新标点和合本) for Chinese.
- **USFM_BOOK** — three-letter USFM code, *not* the book name: `GEN`, `1SA`, `PSA`,
  `JHN`, `REV`. The full table lives in `BibleAPIService.bookCodes`; the cards store
  display names ("1 Corinthians", "Psalm"), and `BibleAPIService.usfmCode(for:)`
  translates them (`Psalm` → `PSA`, since the API calls it `Psalms`).
- **chapter** — integer.

Also useful: `.../books.json` (per-translation book list with chapter counts) and
`.../available_translations.json` (1 MB catalogue of every translation id).

## 3. Response is typed blocks, not `{reference, text}`

```json
{
  "translation": { "id": "eng_web", "name": "World English Bible Classic" },
  "book": { "id": "LEV", "name": "Leviticus" },
  "chapter": {
    "number": 23,
    "content": [
      { "type": "heading", "content": ["The Feasts of Yahweh"] },
      { "type": "verse", "number": 22,
        "content": ["“When you reap the harvest of your land, you must not wholly reap into the corners of your field…"] },
      { "type": "verse", "number": 1,
        "content": [ { "text": "Yahweh is my shepherd;", "poem": 1 },
                     { "text": "I shall lack nothing.", "poem": 2 } ] }
    ]
  }
}
```

Things that bite when decoding it:

1. **`content` items are heterogeneous** — a bare `String` *or* an object
   `{ "text": …, "poem": 1 }` (poetry, Psalms). Decode with a custom `init(from:)`
   that tries `String` first.
2. **Block `type` is not always `verse`** — also `heading`, `hebrew_subtitle`
   (e.g. `"ALEPH"` inside Psalm 119), `subtitle`, `line`. Text blocks belong to
   the verse that *follows* them; `line` blocks continue the previous verse.
3. **Verse numbers are per chapter**, and verse 1 can appear after a heading.
4. Chapter-level keys also include `thisChapterAudioLinks`, `numberOfVerses`,
   `nextChapterApiLink` — ignore them.

`BibleAPIService.flatten(_:)` implements exactly the rules above.

## 4. Using it

```swift
// BiblePassageView already does this on appear:
@State private var chapter: BibleChapter?

private func loadChapter() async {
    guard let card = dailyCardStore.currentCard else { return }
    chapter = try? await BibleAPIService.shared.chapter(
        book: card.book,            // "Leviticus" — from the bundled JSON
        chapter: card.chapter,      // 23
        language: dailyCardStore.appLanguage   // "en" | "zh-Hans"
    )
}
```

`BibleChapter.verses` is `[BibleVerse]` — `number`, optional `heading`, `text` — so the
view can highlight `card.verse` and render the rest as context.

Caching: results are memoised in the actor, and `URLCache` (4 MB memory / 32 MB disk,
`.returnCacheDataElseLoad`) keeps chapters across launches. Chapter text is immutable,
so a stale cache is not a concern.

## 5. Offline behaviour

The card's own verse always renders from the bundled JSON, so the passage screen is never
blank. If the chapter fetch fails, the view shows the verse plus a retry button — it does
not fall back to a spinner or an empty card.

## 6. Licences

- **WEB** — public domain (https://worldenglish.bible).
- **新标点和合本 (cmn_cu1)** — served by helloao; check the `license` object in
  `available_translations.json` before shipping. The app's About sheet currently credits
  Open Translation Bible (CC BY-SA 4.0) for Chinese text; confirm that matches what
  `cmn_cu1` actually is before release.
