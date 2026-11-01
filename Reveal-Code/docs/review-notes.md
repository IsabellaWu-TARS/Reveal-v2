# App Review Notes — Reveal 1.0 (build 1)

Copy the block below into **App Store Connect → App Review Information → Notes**.
It is written for a reviewer opening the app cold, on an iPhone, with no account.

---

## What Reveal is

Reveal is a daily devotional reader. It shows one Bible verse per day as a card.
Tapping the card flips it to a reflection and a one-line action. Everything else
in the app supports that loop: keeping favourites, writing notes, reviewing past
days, reading the surrounding chapter, and an optional daily reminder.

**No account is required. No sign-in of any kind exists in the app.** There is no
purchase, no subscription, and no user-generated content is shared between people.

## First launch

1. A short splash (≈1.5 s, animated leaf) appears.
2. A three-page onboarding appears the first time only: **Continue** twice, then
   **Get Started**. Swiping also works.
3. The Home screen shows today's card.

## Features and how to reach them

| Feature | How to reach it | What to check |
|---|---|---|
| Today's card | Home, centre of screen | Verse, reference, day's colour |
| Flip to reflection | **Tap the card** | Front → Reflection + Action, animated |
| Favourite | Star, top-right of the card | Toggles; persists after relaunch |
| Write a note | With the card flipped, tap the note area under it | Keyboard appears, text saves on dismiss |
| Share | **Long-press the card** → choose an option | Verse / Reflection / Note / Full set. PNG for the card options, text for the note |
| Full chapter | Bottom-left book button → Scripture | Chapter loads; the day's verse is highlighted |
| Calendar | Bottom-right calendar button | Shows the month list; past days open, future days do not |
| Daily reminder | Settings → Daily Reminders | Off by default; turning it on asks for notification permission, then schedules the time you choose |
| Card text colour | Settings → Card Text Colour | Automatic / White / Ink / Custom (system colour picker) |
| Language | Settings → Language | English ↔ 简体中文, applies immediately |
| Appearance | Settings → Appearance | System / Light / Dark |
| Privacy policy | Settings → Privacy Policy | In-app policy, same text as the hosted page |

## Things a reviewer might otherwise flag

- **Notifications are optional and off by default.** Declining the permission leaves
  every feature usable. The reminder is a *local* notification (`UNCalendarNotificationTrigger`,
  repeating daily) — the app does not use remote push and has no push server.
- **The full chapter needs a connection.** Chapter text comes from a public Bible
  API (`https://bible.helloao.org/api/...`). The day's verse is bundled on device
  and remains readable offline; if the request fails the screen shows
  "Couldn't load the full chapter — today's verse still reads offline." with a **Retry**
  button. Nothing crashes or hangs when offline.
- **Future calendar days are intentionally sealed.** Tapping a future date does nothing;
  there is no content to reveal. This is a product decision, not a bug.
- **No permissions beyond notifications.** No camera, photos, contacts, location,
  microphone, or tracking prompt is ever shown.
- **No account deletion flow is needed** because there is no account, and no data
  leaves the device.
- **App Privacy: Data Not Collected.** Notes, favourites, reading history and
  preferences are stored only in the app's own `UserDefaults`. See the data-flow
  audit in `docs/data-flow.md`.

## How to test the core loop in 60 seconds

1. Let onboarding finish → Home shows a card.
2. Tap the card → reflection side appears.
3. Tap the star → fills.
4. Tap the note area → type a word → dismiss → the note shows under the card.
5. Terminate the app (swipe up) → relaunch → the same card, the same note, the star still filled.
6. Open Calendar → tap yesterday (or any day with a dot) → the card for that day opens,
   with its note if one exists.
7. Settings → Daily Reminders → on → time = two minutes from now → close the app →
   the reminder arrives at that time.

## Contact

Isabella Wu — revealmashal@gmail.com

---

### Notes for the release engineer (not for App Store Connect)

- Review the "no account" statement against the build before submitting; the app has
  no networking other than the Bible chapter fetch, so it holds.
- The reminder permission prompt must appear **only** after the user switches the
  toggle on — the build does this; keep an eye on it if the scheduler is refactored.
- If the reviewer is offline for the whole session, every feature except chapter
  loading still works. That is the intended offline floor.
