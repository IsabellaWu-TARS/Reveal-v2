# Data-flow audit — supports the "Data Not Collected" answer

Audited on build **1.0 (1)**, deployment target iOS 17, from source at the time of
writing. Every claim below is checkable with the command shown next to it.

## 1. What the code links against

```
grep -rn "CryptoKit\|CommonCrypto\|SecKey\|CCCrypt" Reveal   → no matches
grep -c "XCRemoteSwiftPackageReference" project.pbxproj      → 0
otool -L Reveal.app/Reveal                                   → system frameworks only
grep -rn "ASIdentifierManager\|ATTrackingManager\|advertisingIdentifier" Reveal → none
grep -rn "print(\|NSLog(\|os_log\|Logger(" Reveal            → none
```

No analytics SDK, no crash reporter, no advertising SDK, no third-party library of
any kind. No IDFA. No logging statements ship in the binary.

## 2. Every outbound request

| # | Destination | When | Payload | Contains user data? |
|---|---|---|---|---|
| 1 | `https://bible.helloao.org/api/{eng_web\|cmn_cu1}/{USFM}/{chapter}.json` | Only when the user taps a verse reference to open a chapter | A book code and a chapter number | No |

That is the complete list. The only other network activity is the system's own
notification delivery, which is local scheduling — no request leaves the device.

What the Bible API necessarily sees is what any HTTPS request exposes: the IP
address, the TLS handshake, and the path. The developer does not operate the
service, does not receive its logs, and has no way to associate a request with a
person. Apple's definition of *collect* is transmitting data off the device in a
way the developer or their partners can access — this does not meet it.

## 3. Everything stored, and where

All of it is `UserDefaults` inside the app's own sandbox. No file leaves the
container; there is no iCloud key-value store, no CloudKit, no shared container.

| Key | Contents | Personal? |
|---|---|---|
| `Notes…` (NotesStore) | Reflection text the user typed | On-device only; never transmitted |
| favourite ids | Card identifiers the user starred | On-device only |
| `ViewedDates` | Dates on which the app was opened | On-device only |
| `AppLanguage`, appearance keys | UI preferences | On-device only |
| `dailyReminderEnabled/Hour/Minute` | Reminder settings | On-device only |
| `cardInkMode`, `cardInkCustomHex` | Card text colour choice | On-device only |
| `CurrentCardDayKey`, `CurrentCardId` | Which card is showing today | On-device only |

Retention: until the user deletes the item or deletes the app. There is no
server-side copy, so there is no retention period to declare.

## 4. Permissions

| Permission | Requested when | Declining breaks anything? |
|---|---|---|
| Notifications | Only after the user turns Daily Reminders on | No — every other feature works |

No camera, photo library, microphone, contacts, location, motion, health, tracking,
or local-network access is requested, and none has a purpose string in the build.

## 5. Third parties

| Party | Role | User data received |
|---|---|---|
| `bible.helloao.org` | Serves chapter text on request | None beyond ordinary request metadata |
| Apple | Notification delivery on device; iCloud device backup if the user enables it | Governed by Apple's terms, not by us |

## 6. Conclusion

**Data Not Collected**, tracking **No**, and no third-party SDK declarations — this
matches the App Privacy answers, the in-app policy, and `PrivacyInfo.xcprivacy`
(`NSPrivacyCollectedDataTypes` empty, `NSPrivacyTracking` false, `UserDefaults`
declared with reason `CA92.1`).

If the app ever adds accounts, analytics, remote push, or crash reporting, this
document and the policy must change in the same release.
