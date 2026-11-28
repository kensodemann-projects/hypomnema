# PLAN-37 — Edit a journal entry within 24 hours

Issue: [#37](https://github.com/kensodemann-projects/hypomnema/issues/37) (OPEN).

Related to [#32](https://github.com/kensodemann-projects/hypomnema/issues/32).

A journal entry already stores an absolute `createdAt` and a wall-clock `localDateTime`. `JournalEntry.revise` and `FirestoreJournalEntryRepository.update` change the subject, mood, text, and private flag and leave both times in place. `JournalEditor` can open with a subject, mood, and text already filled in, but `JournalScreen` only opens it for a new entry and calls `save`. The phone detail built in `_openEntry` and the desktop `JournalEntryDetail` show the mood, when, subject, and text. Neither shows Edit or an "Editable until" note. Firestore rules let the owner update an entry and do not check the time.

**Decisions**

- The window is open when `now` is before or equal to `createdAt` plus 24 hours, and closed when `now` is after that instant.
- The journal note uses the local clock of that absolute deadline. The next local calendar day reads `Editable until 8:02 AM tomorrow`. The same local calendar day reads `Editable until 11:00 PM today`.
- The shared check lives in `lib/core/utils/edit_window.dart`. The journal sentence lives in `journal_list.dart`, beside the other journal display strings.
- `JournalEntryRepository.update` and `firestore.rules` stay as they are. The window decides whether Edit and the note are shown. Save still calls `update`, passes the entry's current `private` value, and does not read the clock.

**Out of scope**

- Make Private, Make Public, Show Content, and hiding a private subject or text.
- I'm Stuck, and any change to the new-entry titles or the "Date and time are set when you save" note.
- A delete action, a security-rule time check, and a clock check inside `update`.
- A timer that hides Edit while the detail sits open. The detail uses `JournalScreen.clock` when it builds.

**Contract**

- Compare absolute instants. `editWindowDeadline` is `createdAt.toUtc().add(Duration(hours: 24))`. `isWithinEditWindow` is false only when `now.toUtc()` is after that deadline.
- The note is present only while the window is open. Its time matches the journal clock style already used by `_time`: no leading hour zero, padded minutes, `AM` or `PM`, seconds dropped.
- `today` when the deadline's local calendar day is now's local calendar day. `tomorrow` when that local calendar day is after now's.
- Phone: Edit is an icon button in the detail top bar. Desktop: Edit is an outlined button on the detail, with the edit icon and the label `Edit`. Both details show the note under the mood and subject row. After the window closes, Edit and the note are absent. There is no Delete control.
- Saving replaces the subject, mood, and text. The visible local date and time stay. `private` stays whatever the entry already had.

**File order**

| Order | Step       | Status | Files |
| ----- | ---------- | ------ | ----- |
| 1     | [STEP-001] | complete | `lib/core/utils/edit_window.dart`, then `test/core/utils/edit_window_test.dart`, then `lib/features/journal/domain/journal_list.dart`, then `test/features/journal/domain/journal_list_test.dart` |
| 2     | [STEP-002] | complete | `lib/features/journal/ui/journal_entry_detail.dart`, then `lib/features/journal/ui/journal_screen.dart`, then `test/helpers/fake_journal_entry_repository.dart`, then `test/features/journal/ui/journal_screen_test.dart` |

**Commit gate** — the human commits. A spot-check does not replace the gate.

```bash
make web
make check
```

`make check` runs `format-check`, `analyze`, and `test`. Every commit-gate command must succeed with no warning or error before that commit, except the Firebase CLI notice that another emulator suite is already running for project `kws-hypomnema`. The rules tests start their own emulator on port 8180 while the dev suite stays on port 8080. That notice does not fail the gate.

## [STEP-001] Add the shared 24-hour window and the journal note

**Status:** complete

**Acceptance criteria:** Callers can ask whether an absolute creation timestamp is still inside the 24-hour window, and the journal note names that deadline as today or tomorrow.

**Files**

1. `lib/core/utils/edit_window.dart` — `editWindowDeadline` and `isWithinEditWindow` for any later feature.
2. `test/core/utils/edit_window_test.dart` — the inclusive boundary, using UTC instants so the host zone does not matter.
3. `lib/features/journal/domain/journal_list.dart` — `journalEditableUntilNote`, or null when the window is closed.
4. `test/features/journal/domain/journal_list_test.dart` — the mock-up sentence, the same-day sentence, and the boundary.

**Change**

Add `editWindowDeadline(DateTime createdAt)` and `isWithinEditWindow({required DateTime createdAt, required DateTime now})` as above. Do not read `localDateTime` here.

Add `journalEditableUntilNote({required DateTime createdAt, required DateTime now})`. It returns null when `isWithinEditWindow` is false. Otherwise it formats `editWindowDeadline(createdAt).toLocal()` with the existing journal time style and the `today` or `tomorrow` word from the contract.

Cover at least these cases:

- `now` equal to `createdAt`, equal to the deadline, and one microsecond after the deadline.
- Created at 8:02 AM local on November 14 and viewed at noon that day: `Editable until 8:02 AM tomorrow`.
- Created at 11:00 PM local on November 13 and viewed at 10:00 AM the next day: `Editable until 11:00 PM today`.
- `now` equal to a deadline that falls on now's local calendar day: the note is still present and uses `today`. One microsecond later the note is null.
- A creation instant with seconds still displays the minute, the same way journal row times do.

**Spot-check**

```bash
flutter test test/core/utils/edit_window_test.dart test/features/journal/domain/journal_list_test.dart
```

- The new window and note cases pass, and the existing journal list cases still pass.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error except the emulator notice in the commit gate.

**Commit:** `make web`, then `make check`, succeed with no warning or error except that emulator notice.

## [STEP-002] Show Edit on the phone and desktop details and save through the same editor

**Status:** complete

**Acceptance criteria:** Within 24 hours of `createdAt`, phone and desktop details offer Edit and the note, in light and dark themes. Edit opens the existing editor filled with the subject, mood, and text. Saving those fields leaves the local date and time unchanged. After 24 hours, Edit and the note are gone. There is no delete action.

**Files**

1. `lib/features/journal/ui/journal_entry_detail.dart` — the note under the mood and subject row, and the desktop Edit button when an edit callback is set.
2. `lib/features/journal/ui/journal_screen.dart` — the phone top-bar Edit, the desktop detail Edit, and save through `update`.
3. `test/helpers/fake_journal_entry_repository.dart` — record each `update` the way `saves` records a create.
4. `test/features/journal/ui/journal_screen_test.dart` — phone and desktop, inside and outside the window, light and dark, and a save.

**Change**

Keep `JournalEditor` as the new-entry editor. Pass the entry's subject, mood, and text into the parameters it already has. Do not add a delete control, and do not change `journal_editor.dart`.

`JournalEntryDetail` takes an optional note string and an optional edit callback. The note is a schedule icon and the sentence, `bodySmall` in `onSurfaceVariant`, on both form factors. The icon is `Icons.schedule` at 16 pixels in the same color. When the callback is set, the header row ends with an `OutlinedButton.icon`: `Icons.edit`, the label `Edit`, foreground `colorScheme.primary`, and border `colorScheme.outline`. Leave the button label on the button's own text role. When the note and callback are absent, the detail matches what it shows today.

On the phone, Edit is a 48×48 `IconButton` in the detail top bar, tooltip `Edit`, `Icons.edit`, foreground `onSurfaceVariant`, the same treatment as Back. It is absent when the window is closed. The phone detail is a private widget that watches `repository.watch()` for the open entry's id and reads `JournalScreen.clock` when it builds, so the entry under the editor is the saved one. If that id disappears, pop the route. Open the editor from the detail route's navigator, above the detail. Desktop stays a dialog over the journal, as Write already is.

The edit submit calls `repository.update` with the new subject, mood, and text and the entry's existing `private`. It does not call `save`. After a successful save the editor pops, the phone detail still shows that entry with the new subject, mood, and text, and the desktop detail does the same for the selected entry. The visible when strings stay on the original local date and time.

Use `journalEditableUntilNote` with `entry.createdAt` and the screen clock. Do not derive the window from `localDateTime`.

The screen tests keep the current detail assertions and add:

- The November 14, 8:02 AM entry viewed at noon shows `Editable until 8:02 AM tomorrow` and Edit. An entry created on November 12 does not show Edit or the note.
- An entry whose `localDateTime` is old and whose `createdAt` is still inside the window shows Edit. An entry whose wall clock is recent and whose `createdAt` is outside the window does not.
- Phone and desktop, light and dark: the note uses `bodySmall` and `onSurfaceVariant`; the phone Edit icon uses `onSurfaceVariant`; the desktop Edit button uses `primary` and `outline`.
- No `Delete` text and no `Icons.delete` on either detail or in the editor.
- Saving a changed subject, mood, and text from either form factor records one update, no create, and the same `private` value. A private entry stays private. The detail shows the new subject and mood, and the when text is unchanged. The editor title stays `New entry` on the phone and `New journal entry` on the desktop.

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_screen_test.dart
```

- The new edit cases pass, and the existing journal screen cases still pass.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error except the emulator notice in the commit gate.

**Commit:** `make web`, then `make check`, succeed with no warning or error except that emulator notice.
