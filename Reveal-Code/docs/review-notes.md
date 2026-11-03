# App Review Notes — Reveal 1.0 (build 1)

Copy the block below into **App Store Connect → App Review Information → Notes**.
It is written for a reviewer opening the app cold, on an iPhone, with no account.

---

## What Reveal is

Reveal is a daily devotional reader. It shows one Bible verse per day as a card.
Tapping the card flips it to a reflection and a one-line action. Everything else
supports that loop: favourites, notes, past days, the surrounding chapter, and an
optional daily reminder.

**No account. No sign-in. No purchase or subscription. No user content is shared
between people.** Notes, favourites and reading history live only in the app's own
container on the device.

## First launch

1. A short animated splash (≈1.5 s) appears.
2. **Choose your language** — English or 简体中文. It applies immediately and can be
   changed later in Settings.
3. **A five-step tour of the home screen** runs once: Read the chapter, Calendar,
   Share, Notes, Settings. A ring highlights the real control, a note explains it,
   and **tapping anywhere advances**. The last tap closes the tour; **Skip** exits it.
   Dots show progress.
4. Home shows today's card.

## Features and how to reach them

The controls sit at the corners of the card:

| Position | Control |
|---|---|
| Top-left | Read the chapter |
| Top-right | Calendar |
| Bottom-left | Share |
| Bottom-centre | Notes (pill) |
| Bottom-right | Settings |

| Feature | How to reach it | What to check |
|---|---|---|
| Today's card | Home, centre | Verse, reference, the day's colour |
| Flip to reflection | **Tap the card** | Front → Reflection + Action, animated |
| Favourite | Star, top-right of the card | Toggles; persists after relaunch |
| Write a note | Bottom-centre **Notes** pill | Editor opens full screen; text saves as you type and on dismiss |
| Share | Bottom-left **share** button | Verse / Reflection / Note / Full set; the card options produce a PNG of the card |
| Full chapter | Top-left **book** button | English chapter loads from the public API; Chinese chapter is bundled and works offline; today's verse is highlighted |
| Calendar | Top-right **calendar** button | Month list; past days open, future days are intentionally sealed |
| Daily reminder | Settings → Daily Reminders | Off by default; switching it on asks for notification permission, then schedules that time |
| Scripture script | Settings → 经文显示 (Chinese only) | 简体 / 繁體; identical text, only the character forms change |
| Card text colour | Settings → Card Text Colour | Automatic / White / Ink / Custom |
| Card colour | Settings → Card Colour | Daily palette, or two custom colours |
| Language | Settings → Language | English ↔ 简体中文, applies immediately |
| Appearance | Settings → Appearance | System / Light / Dark |
| Privacy policy | Settings → Privacy Policy | In-app policy, same text as the hosted page |
| Version | Settings, bottom | 1.0 (1) |

## Scripture editions and rights

Two texts, both public domain:

- **English — World English Bible (WEB)**, public domain. Chapters are fetched on
  demand from `https://bible.helloao.org/api/eng_web/…`.
- **Chinese — 官話和合本, 1919 edition (Chinese Union Version)**, public domain; its
  1919 copyright has expired. The complete text is **bundled with the app** and read
  offline — no request is made for Chinese chapters.

The 1919 text is reproduced as printed: its own punctuation, its own archaic forms,
and the full-width space before 神 in the "God" edition. Settings → 经文显示 offers a
simplified-character rendering, which is a character-for-character conversion of the
same text — wording, punctuation and verse boundaries are unchanged. The app does not
use the 1989 "new punctuation" revision, whose rights are administered by the United
Bible Societies and the Hong Kong Bible Society.

Attribution and the full statement are in Settings → Sources & Licenses.

## Things a reviewer might otherwise flag

- **Notifications are optional and off by default.** Declining leaves every feature
  usable. The reminder is a *local* notification (`UNCalendarNotificationTrigger`,
  repeating daily) — no remote push, no push server.
- **Only English chapters need a connection.** If the request fails the screen shows
  "Couldn't load the full chapter — today's verse still reads offline." with **Retry**.
  Nothing crashes or hangs offline; Chinese chapters never touch the network.
- **Future calendar days are intentionally sealed.** Tapping a future date does
  nothing; there is no content to reveal.
- **No permissions beyond notifications.** No camera, photos, contacts, location,
  microphone, or tracking prompt is ever shown.
- **No account deletion flow is needed** — there is no account and no data leaves the
  device.
- **App Privacy: Data Not Collected.** The only outbound request is the English
  chapter fetch, carrying a book code and chapter number. See `docs/data-flow.md`.

## How to test the core loop in 60 seconds

1. Finish onboarding → Home shows a card.
2. Tap the card → reflection side appears.
3. Tap the star → fills.
4. Tap the **Notes** pill → type a word → dismiss → the note shows under the card.
5. Swipe the app away → relaunch → same card, same note, star still filled.
6. Calendar → tap a day with a dot → that day's card opens, with its note if any.
7. Settings → Daily Reminders → on → set the time two minutes ahead → close the app →
   the reminder arrives.

## Contact

Isabella Wu — revealmashal@gmail.com

---

### Notes for the release engineer (not for App Store Connect)

- Re-read the "no account" statement against the build before submitting: the only
  network call is the English chapter fetch, so it holds.
- The reminder permission prompt must appear **only** after the toggle is switched on;
  keep an eye on that if the scheduler is refactored.
- Offline for the whole session: everything works except English chapter loading.
- Before uploading, confirm the App Privacy answers (Data Not Collected, no tracking)
  still match `Reveal/PrivacyInfo.xcprivacy`.
