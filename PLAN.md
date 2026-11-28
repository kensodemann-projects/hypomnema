# PLAN-38 — Make a journal entry private or public

Issue: [#38](https://github.com/kensodemann-projects/hypomnema/issues/38) (OPEN). Related to [#32](https://github.com/kensodemann-projects/hypomnema/issues/32).

A journal entry already stores `private`. `JournalEntry`, `JournalEntryRepository.save`, and `JournalEntryRepository.update` read and write it, and `revise` changes `private` while leaving `id`, `localDateTime`, and `createdAt` as they are. The screens do not use it. `JournalScreen._submit` always saves `private: false`, and an edit calls `update` with `editing.private` unchanged. `JournalEditor.onSubmit` takes subject, mood, and text only, and the editor has no Private switch. `_JournalEntryRow` always paints `entry.subject`. `JournalEntryDetail` always paints the subject and the text, and Edit is passed whenever `journalEditableUntilNote` is non-null, including for a private entry. The seeded private entry "Quiet thought" is asserted as visible subject and text in `test/features/journal/ui/journal_screen_test.dart`.

**Decisions**

- The detail headline stays "Private entry" after Show Content. The subject appears in the reveal banner.
- The editable-until note stays on a private entry that is still inside the 24-hour window, including while the cover is up. The private mock-ups omit it because that sample is past the window. Edit stays hidden until Show Content.
- Show Content lasts for this viewing of that entry. Phone Back, and selecting another desktop row, end it. Opening the editor and saving does not. A later watch event for the same id keeps the reveal while `private` stays true. Make Private on the open entry starts covered. Make Public shows the writing.
- Phone and desktop each use the copy and button style of their own mock-up.
- Make Private and Make Public call the existing `JournalEntryRepository.update` with the same subject, mood, and text and the flipped `private`. There is no new repository method.
- A failed privacy update leaves the open entry unchanged and shows a floating snackbar, "The entry could not be updated."

**Out of scope**

- Journaling goal and mood trend. The issue leaves those to features 4 and 5. The stored flag is what those screens will read later.
- I'm Stuck. The editor mock-ups show it; this issue does not.
- A blank subject. The editor still requires a subject.
- The goal pill and the Entries, Mood Trend, and Journaling Goal tabs drawn on the journal mock-ups.
- Deleting an entry.
- The editor titles. An edit still says "New entry" on the phone and "New journal entry" on the desktop.
- Firestore rules. An owner write under `users/{userId}` already allows `private`.

**Copy**

| Surface | Phone | Desktop |
| --- | --- | --- |
| List label, in place of the subject | lock + "Private entry" | lock + "Private entry" |
| Detail headline, in place of the subject | lock + "Private entry" | lock + "Private entry" |
| Cover title | "This entry is private" | "This entry is private" |
| Cover body | "Showing it is for this viewing only and won't change the private setting." | "The subject and text are hidden. Showing them is for this viewing only and won't change the private setting." |
| Show Content | "Show Content" | "Show Content" |
| Reveal banner | the subject, then "Hide" | "{subject} · Showing private content for this viewing", then "Hide" |
| Privacy action | outlined "Make Private" or "Make Public" | text "Make Private" or "Make Public" |
| Editor switch | "Private" / "Hide subject and text until Show Content" | "Private" / "Hide the subject and text until you choose Show Content" |

Text roles are the same on both form factors. "Private entry" in the list is `titleMedium`, one line, ellipsis. "Private entry" in the detail headline is `headlineSmall`. The cover title is `titleMedium`. The cover body and the banner sentence are `bodyMedium`. The banner subject is `titleSmall`. The switch title is `titleMedium` and its support line is `bodySmall`. Keep each role's size, weight, height, and letter spacing. List and headline "Private entry", the cover body, the banner, and the switch support use `onSurfaceVariant`. The cover title uses `onSurface`. A selected desktop row still paints the private label `onSurfaceVariant`; the when-line still uses `onPrimaryContainer` when selected.

**File order**

| Order | Step | Status | Files |
| ----- | ---- | ------ | ----- |
| 1 | [STEP-001] | | `lib/features/journal/ui/journal_entry_list.dart`, then `test/features/journal/ui/journal_screen_test.dart` |
| 2 | [STEP-002] | | `lib/features/journal/ui/journal_entry_detail.dart`, then `lib/features/journal/ui/journal_screen.dart`, then `test/features/journal/ui/journal_screen_test.dart` |
| 3 | [STEP-003] | | `lib/features/journal/ui/journal_entry_detail.dart`, then `lib/features/journal/ui/journal_screen.dart`, then `test/helpers/fake_journal_entry_repository.dart`, then `test/features/journal/ui/journal_screen_test.dart` |
| 4 | [STEP-004] | | `lib/features/journal/ui/journal_editor.dart`, then `lib/features/journal/ui/journal_screen.dart`, then `test/features/journal/ui/journal_editor_test.dart`, then `test/features/journal/ui/journal_screen_test.dart` |

**Commit gate**

The human commits. A spot-check does not replace the gate. `make check` already runs `test`.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit. One notice is allowed and does not fail the gate: the Firebase CLI notice that another emulator suite is already running for project `kws-hypomnema`. The rules tests start their own emulator on port 8180 while the dev suite stays on port 8080.

## [STEP-001] Show a private list row as a lock and "Private entry"

**Status:**

**Acceptance criteria:** A private row shows its mood, date, and time, with a lock and "Private entry" in place of the subject, on the phone and the desktop, in light and dark. A public row still shows its subject.

**Files**

1. `lib/features/journal/ui/journal_entry_list.dart` — private rows replace the subject.
2. `test/features/journal/ui/journal_screen_test.dart` — the list assertions expect the private label.

**Change**

In `_JournalEntryRow`, when `entry.private` is true, paint a lock at 16px and the text "Private entry" instead of `entry.subject`. Use `titleMedium`, `maxLines: 1`, and `TextOverflow.ellipsis`. Color that label and the lock `onSurfaceVariant`, including when the desktop row is selected. Keep `MoodSwatch` and `journalRowWhen` as they are. A public row still paints `entry.subject` with the current selected and unselected colors.

The row's rendered text must not include the real subject. Scope finders to `journal-entry-<id>` when more than one row says "Private entry".

Update the phone list test that currently expects "Quiet thought" on the seeded private row. That row shows "Private entry" and "Thu, Nov 12 · 10:15 PM", mood 2, and not "Quiet thought". Add the same list assertion on the desktop seeded journal. In the existing light and dark phone and desktop journal tests, a private row uses `onSurfaceVariant` for the label and the lock in both themes; a selected desktop private row keeps that label color and paints the when-line `onPrimaryContainer`.

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_screen_test.dart
```

- The private seeded row shows "Private entry", its when-line, and its mood, and omits "Quiet thought".
- Public subjects such as "Early run" still show.
- Light and dark private rows use the scheme colors above.

**Done when:** Those list outcomes hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-002] Hide private writing behind Show Content for one viewing

**Status:**

**Acceptance criteria:** A private detail shows the date, time, mood, and a private cover in place of the subject and text. Show Content reveals the writing for that viewing only. Hide, Back, and selecting another desktop entry return the cover. The private flag is unchanged. Edit appears only after Show Content, and only while the 24-hour window is open.

**Files**

1. `lib/features/journal/ui/journal_entry_detail.dart` — cover, banner, and hidden writing.
2. `lib/features/journal/ui/journal_screen.dart` — reveal state and Edit gating for both shells.
3. `test/features/journal/ui/journal_screen_test.dart` — cover, reveal, hide, leave, and Edit gating.

**Change**

`JournalEntryDetail` stays stateless. Add `contentRevealed`. When `entry.private` is false, keep today's subject, text, and Edit behavior. When it is true:

- The headline slot is a 24px lock and "Private entry" in `headlineSmall`, color `onSurfaceVariant`. The date line and large mood swatch stay. The real subject is absent from that slot.
- While `contentRevealed` is false, omit the subject, the paragraphs, and the desktop text card. Show a cover keyed `journal-private-cover`: `Icons.visibility_off` at 44px in `onSurfaceVariant` at 60% opacity, the cover title in `titleMedium`, the form-factor cover body in `bodyMedium`, and a `FilledButton.tonal` keyed `journal-show-content` with `Icons.visibility` and "Show Content". The cover is centered, filled with `surface`, padded 36 by 20 on the phone and 48 by 32 on the desktop, and outlined with a dashed rounded rect in `outline` at `borderWidth` and `cardRadius`. Paint that dash in this file. Add no package.
- `onShowContent` runs from that button.
- While `contentRevealed` is true, hide the cover. Show a banner keyed `journal-private-banner` on `surfaceContainerHigh`, radius `rowRadius`, foreground `onSurfaceVariant`, with `Icons.visibility`. The phone banner is the subject in `titleSmall` and a text "Hide" button. The desktop banner is the subject in `titleSmall`, then " · Showing private content for this viewing" in `bodyMedium`, and the same Hide button. Key Hide `journal-hide`. `onHide` runs from it. Under the banner, show the paragraphs in `bodyLarge`. The desktop paragraphs stay in the existing detail card. The phone paragraphs stay uncarded.

`journal_screen.dart` owns the reveal in one private function used by both shells. `_PhoneEntryScreenState` holds the flag for the open entry, starting covered. `_JournalScreenState` holds it for `_selectedId`. Set the flag false when the phone route is created, when the desktop selection changes, and when the open entry changes from public to private. Keep it when a watch event updates the same private entry. Show Content sets it true. Hide sets it false. Neither path calls the repository.

Edit uses one private function for both shells. Show the phone bar button and pass desktop `onEdit` only when the entry is inside the window and, if it is private, the content is revealed. Past the window, Edit stays absent after Show Content. The editable-until note still follows the window alone, so a covered in-window private entry shows the note and hides Edit.

Update the tests that open the seeded private entry and expect "Quiet thought" immediately. On phone and desktop the first frame shows the cover copy for that form factor, the when-line, and mood 2, and omits the subject and both paragraphs. Show Content then shows the banner and both paragraphs and still omits a repository update. Hide restores the cover and still omits an update. Phone Back and a later open start covered. On the desktop, revealing, selecting another row, and reselecting the private row starts covered. The in-window private edit tests tap Show Content before Edit; before that tap, `journal-edit` is absent, and after save the banner subject is the revised subject while `private` stays true and the when-line is unchanged. A past-window private entry has no `journal-edit` after Show Content. Assert the cover and banner colors from the scheme in light and dark.

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_screen_test.dart
```

- A private detail opens covered, reveals on Show Content, and covers again on Hide, Back, and a desktop reselection, with no repository update.
- Edit is absent until Show Content, and absent after it when the window is closed.
- An in-window edit after Show Content still saves the revised fields and keeps `private` true.

**Done when:** Those viewing outcomes hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-003] Switch privacy from the entry details

**Status:**

**Acceptance criteria:** Make Private and Make Public are available on the phone and the desktop at any time, including past the 24-hour window and before Show Content. The stored flag flips. The open writing hides or shows with that flag. The date and time stay.

**Files**

1. `lib/features/journal/ui/journal_entry_detail.dart` — the privacy button on each form factor.
2. `lib/features/journal/ui/journal_screen.dart` — `update` with the flipped flag.
3. `test/helpers/fake_journal_entry_repository.dart` — a way for `update` to fail.
4. `test/features/journal/ui/journal_screen_test.dart` — both directions, both form factors, and the failure snackbar.

**Change**

Add a privacy button keyed `journal-privacy`. Public entries say "Make Private" with `Icons.lock`. Private entries say "Make Public" with `Icons.lock_open`. It is shown for every entry, inside the window and past it, and on a private entry both before and after Show Content.

On the phone the button is outlined, with primary foreground and an `outline` side, matching Edit's outlined colors. On a public entry it sits at the end of the editable-until row when that note is present, and at the start of that row when the note is absent. On a private entry it is its own row under the header, aligned to the start; the note, when present, stays above it. On the desktop it is a text button in the detail actions, after Edit when Edit is visible. Desktop text-button foreground is `primary`.

`onTogglePrivacy` calls `repository.update` with the open entry's subject, mood, and text and `private` flipped. `revise` already keeps `localDateTime` and `createdAt`. On success the watch event delivers the revised entry. The reveal rule from [STEP-002] covers a newly private entry and shows a newly public entry's subject and text, with the headline returning to `entry.subject`. On a thrown update, leave the flag and the open detail as they were and show a floating snackbar whose content is "The entry could not be updated."

`FakeJournalEntryRepository` gains an optional `updateError`. When it is set, `update` records the attempt, throws, and does not publish.

Tests, on phone and desktop: Make Private on a public entry records one update with the same subject, mood, and text and `private: true`, and the detail shows the cover and "Private entry" while the when-line is unchanged. Make Public on a private entry, without Show Content, records `private: false` and shows the subject and text. The same actions work on an entry past the window. A thrown update shows the snackbar, leaves the previous writing on screen, and does not publish a new flag. Light and dark assert the outlined phone button and the desktop text button use `primary` on their foreground.

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_screen_test.dart
```

- Make Private and Make Public flip `private` through `update` on both form factors, inside and past the window.
- The detail covers or reveals with the new flag, and the when-line stays.
- A failed update shows "The entry could not be updated." and leaves the entry unchanged.

**Done when:** Those toggle outcomes hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-004] Save the Private switch from the editor

**Status:**

**Acceptance criteria:** The editor has a Private switch whose copy matches the editor mock-ups. A new entry defaults to public. Save stores the switch value. An edit opens with the entry's current flag and can change it.

**Files**

1. `lib/features/journal/ui/journal_editor.dart` — the switch and the `private` argument.
2. `lib/features/journal/ui/journal_screen.dart` — pass the switch into `save` and `update`.
3. `test/features/journal/ui/journal_editor_test.dart` — copy, default, and submitted flag.
4. `test/features/journal/ui/journal_screen_test.dart` — a saved private entry and an edit that changes the flag.

**Change**

Extend `JournalEditor.onSubmit` with `required bool private`. Add a `private` constructor field, defaulting to false. Seed a new entry off and an edit from `entry.private`.

Under the journal field, on both form factors, paint a row keyed `journal-private`: a `Switch` on the left, then "Private" in `titleMedium` and the form-factor support line in `bodySmall`, color `onSurfaceVariant`. The switch does not affect whether Save is enabled. Save passes the switch value. The existing save-failure snackbar still covers a failed submit.

`JournalScreen` stops forcing `private: false` on create and stops resubmitting `editing.private` on update. Both calls use the value from the editor. The editor still opens with that entry's subject, mood, and text.

Update the editor submission records so existing saves expect `private: false`. Add phone and desktop editor tests: the support copy matches the table above, the switch starts off for a new entry, it starts on when `private: true` is passed, and Save submits the toggled value. From the journal screen, turning the switch on and saving replaces the empty state with a "Private entry" row whose detail is covered, and the recorded save is `private: true`. Editing that entry opens the switch on; turning it off and saving records `private: false`, shows the subject, and keeps the when-line. The existing in-window private edit that does not touch the switch still saves `private: true`.

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_editor_test.dart test/features/journal/ui/journal_screen_test.dart
```

- The switch copy differs by form factor, defaults off, and is submitted as `private`.
- A new private entry is stored private and opens covered.
- An edit can turn the flag off, and an edit that leaves the switch on keeps it on.

**Done when:** Those editor outcomes hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.
