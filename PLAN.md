# PLAN-35 — Write a journal entry

Issue: [#35](https://github.com/kensodemann-projects/hypomnema/issues/35) (OPEN).

Related to [#32](https://github.com/kensodemann-projects/hypomnema/issues/32).

Selecting Journal in `Shell` (`lib/app/shell.dart`) shows the centered label `Journal` from `_ShellContent`. `MoodPicker` (`lib/features/journal/ui/mood_picker.dart`) already reports a mood from 1 to 5, and reports none when `value` is null. `JournalEntry.create` and `FirestoreJournalEntryRepository.save` (`lib/features/journal/domain/journal_entry.dart`, `lib/features/journal/data/journal_entry_repository.dart`) already require a subject, a mood from 1 to 5, and text, trim the subject and text, and on `save` write `localDateTime` and `createdAt`. No screen calls `save`. `MainApp` (`lib/app/app.dart`) receives only `AuthService`.

**Decisions**

- The Journal destination keeps a centered filled **Write** button where the centered `Journal` label is now. Write opens the editor. Close, Cancel, and a successful Save return to that button.
- The window width chooses the presentation, using the shell cutoff: width above 600 opens the desktop dialog; 600 and below pushes the phone page.
- Both layouts show `Date and time are set when you save` under the title.
- A new entry starts with an empty subject, no mood, and empty text. Save stays disabled until the trimmed subject, a mood from 1 to 5, and the trimmed text are all present. There is no validation message.
- Subject is required, so its label carries the same required asterisk as Mood and Journal. The subject field has no placeholder.
- The journal field hint is `Write whatever is on your mind…` on both layouts.
- The first save calls `JournalEntryRepository.save` with `private: false`. That existing method writes the local date and time and the absolute creation timestamp.
- A failed save leaves the editor open and shows a floating snackbar, `The entry could not be saved.`, with the shell sign-out error colors (`errorContainer` background, `error` text).
- Journal text uses the app font at 16px with line height 1.7. The sign-in quote already follows the mock without bundling Lora.
- This Write button is the centered button on the current Journal surface. The entries-screen floating action button arrives with the list.

**Out of scope**

- The entries list, empty state, and entry details (#36).
- Editing an existing entry (#37).
- The Private switch, Make Private, and Make Public (#38).
- I'm Stuck, the prompt card, and the prompt list (#39).
- The Journal header pill, the Mood Trend tab, and the Journaling Goal tab.
- Changes to `JournalEntry` or `FirestoreJournalEntryRepository`. Their save path already stores both timestamps.

**Contract**

- Phone title: `New entry`. Desktop title: `New journal entry`.
- Date line, both layouts: `Date and time are set when you save`.
- Field labels: `Subject`, `Mood`, `Journal`. Each label includes a required asterisk in `colorScheme.error`.
- Journal hint: `Write whatever is on your mind…`.
- Actions: `Write`, Close (`Icons.close`, tooltip `Close`), `Cancel` on desktop, `Save`. Desktop Save includes `Icons.check`.
- Save failure: `The entry could not be saved.`
- A saved entry goes through `save` with the trimmed subject, the selected mood, the trimmed text, and `private: false`.

**File order**

| Order | Step       | Status | Files |
| ----- | ---------- | ------ | ----- |
| 1     | [STEP-001] |        | `lib/features/journal/ui/journal_editor.dart`, then `test/features/journal/ui/journal_editor_test.dart` |
| 2     | [STEP-002] |        | `lib/features/journal/ui/journal_screen.dart`, then `lib/app/shell.dart`, then `lib/app/app.dart`, then `lib/main.dart`, then `test/features/journal/ui/journal_screen_test.dart`, then `test/app/shell_test.dart`, then `test/app/app_test.dart` |

**Commit gate** — the human commits. A spot-check does not replace the gate.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit, except the Firebase CLI notice that another emulator suite is already running for project `kws-hypomnema`. The rules tests start their own emulator on port 8180 while the dev suite stays on port 8080. That notice does not fail the gate.

## [STEP-001] Build the journal editor

**Status:**

**Acceptance criteria:** The phone editor is a full-screen page with Close and Save, the desktop editor is a 720px dialog with Close, Cancel, and Save, and both show the date line under the title in light and dark themes. Save stays disabled until a subject, a mood from 1 to 5, and journal text are present, then calls `JournalEntryRepository.save` with `private: false` and dismisses. A failed save stays on the editor and shows the failure snackbar.

**Files**

1. `lib/features/journal/ui/journal_editor.dart` — phone page and desktop dialog for a new entry.
2. `test/features/journal/ui/journal_editor_test.dart` — layout, disabled Save, save, dismiss, and failure.

**Change**

Add `JournalEditor`. It takes a `JournalEntryRepository` and a `desktop` flag. Widgets come from `package:material_ui/material_ui.dart`. The phone widget is a `Scaffold`. The desktop widget is a `Dialog`. Close, Cancel, and a successful Save call `Navigator.pop`. A second Save while a save is in flight does not call the repository again, and Close and Cancel wait until that save finishes.

The form is a subject field, the shared `MoodPicker` starting at null, and a journal text field. Labels sit above the fields: 12px, weight 500, `onSurfaceVariant`, with a 4px gap and a required asterisk in `colorScheme.error`. Subject and journal text start empty. Subject uses a 14px field, 8px radius, 11px by 14px padding, an `outline` border, and a 2px `primary` border when focused (padding 10px by 13px so the box stays put). Journal text is 16px with height 1.7, at least 220px tall on the phone and 260px tall on the desktop, and shows the hint from the contract. The form omits I'm Stuck, the prompt card, and Private.

Phone chrome, from `docs/ui-mockups/phone/journal-editor.html`: a surface-colored page; a top bar at least 64px tall with 4px left padding, a 48px Close icon in `onSurfaceVariant`, the title block, and a primary text **Save**. The title is `New entry` at 18px, weight 400. The date line is 12px `onSurfaceVariant` directly under the title. The form body scrolls, with padding 8px, 20px, 24px and a 14px gap.

Desktop chrome, from `docs/ui-mockups/desktop/journal-editor.html` and `desktop/shared.css`: surface dialog, width 720, maximum height of the viewport minus 64, padding 24, radius 28, column gap 16, scrollable. The header row holds the title and date line, then a 36px Close icon. The title is `New journal entry` at 22px, weight 400. The action row is aligned to the end with an 8px gap: a primary text **Cancel**, then a filled **Save** with `Icons.check` in `primary` and `onPrimary`. The opener supplies `colorScheme.scrim` as the barrier color.

Save's `onPressed` is null until the trimmed subject, a mood from 1 to 5, and the trimmed text are all present. Save then calls `repository.save` with those trimmed values, the selected mood, and `private: false`. Success pops the route. Any failure shows the floating snackbar from the contract and leaves the route open.

Add phone and desktop previews in light and dark, following `MoodPicker` and `ConfirmationDialog`. The preview repository stays inside this file and returns a `JournalEntry` from `JournalEntry.create` without touching Firebase.

**Spot-check**

`flutter test test/features/journal/ui/journal_editor_test.dart`

- Phone and desktop, in light and dark, show the contract copy, the required asterisks in `colorScheme.error`, the date line in `onSurfaceVariant`, and the surface background. Desktop Save uses `primary` and `onPrimary`. The dialog is 720px wide with a 28px radius. Phone journal text is at least 220px tall; desktop journal text is at least 260px tall.
- Save is disabled for an empty form, a whitespace subject, whitespace text, and a missing mood. The repository receives no `save` call.
- After a subject, a mood, and text are entered, Save calls `save` once with the trimmed subject, that mood, the trimmed text, and `private: false`, then the route pops. `update` is not called.
- A second tap while the first save is still running does not call `save` again.
- When `save` throws, the editor stays open and the snackbar shows `The entry could not be saved.` on `errorContainer` with `error` text.
- The editor shows none of `I'm Stuck`, `Private`, or `Prompt`.

**Done when:** acceptance criteria hold, and the commit-gate commands succeed with no warning or error, except the allowed Firebase emulator notice.

**Commit:** the commit-gate commands succeed with no warning or error, except the allowed Firebase emulator notice.

## [STEP-002] Open the editor from Journal

**Status:**

**Acceptance criteria:** Journal shows a centered Write button in place of the centered `Journal` label. Write opens the phone page or the desktop dialog, and Close, Cancel, and a successful Save return to Write. Dashboard and Archive stay centered labels. A successful save from this path is the repository's first `save`.

**Files**

1. `lib/features/journal/ui/journal_screen.dart` — centered Write button and the opener.
2. `lib/app/shell.dart` — Journal destination shows `JournalScreen`.
3. `lib/app/app.dart` — `MainApp` and `Shell` receive the repository.
4. `lib/main.dart` — construct `FirestoreJournalEntryRepository` and pass it to `MainApp`.
5. `test/features/journal/ui/journal_screen_test.dart` — open, dismiss, and save from Write.
6. `test/app/shell_test.dart` — Journal shows Write; sign-out from Journal still works.
7. `test/app/app_test.dart` — supply a journal repository to `MainApp`.

**Change**

Add `JournalScreen`. It takes a `JournalEntryRepository` and centers a filled **Write** button (`Key('journal-write')`) on the same surface that now centers the destination label. Write reads `MediaQuery.sizeOf(context).width`. Above 600, it calls `showDialog` with `JournalEditor(desktop: true)` and `barrierColor` set to `colorScheme.scrim`. At 600 and below, it pushes a full-screen `MaterialPageRoute` with `JournalEditor(desktop: false)`. The phone route covers the shell, including the bottom navigation bar.

`Shell` takes the repository and, for the Journal destination only, builds `JournalScreen` instead of `_ShellContent`. Dashboard and Archive keep `_ShellContent` and `Key('shell-content')`. `MainApp` takes the repository and passes it to `Shell`. `main` constructs `FirestoreJournalEntryRepository` with `FirebaseFirestore.instance` and `FirebaseAuth.instance` and passes it to `MainApp` beside `FirebaseAuthService`.

Update the shell tests that select Journal and then expect the `shell-content` text `Journal`. Those cases expect `journal-write` and no `shell-content` while Journal stays selected:

- `Given the phone shell, when Journal and Archive are tapped, then each destination is selected`
- `Given the desktop shell, when Journal and Archive are tapped, then each destination is selected`
- `Given Journal is selected on the phone shell, when the width becomes 601, then Journal stays selected`
- `Given Journal is selected on the phone shell, when Sign out is tapped, then the confirmation dialog opens`
- `Given Journal is selected on the desktop shell, when Sign out is activated from the keyboard, then the confirmation dialog opens`
- `Given Journal is selected on the desktop shell, when Sign out is tapped, then the confirmation dialog opens`
- `Given the phone sign-out dialog, when Cancel is tapped, then Journal stays selected`
- `Given the desktop sign-out dialog, when Cancel is tapped, then Journal stays selected`

`pumpShell` passes a fake repository. Archive and Dashboard still expect their labels through `shell-content`. `app_test` passes a fake repository into `MainApp`. The sign-out flow that taps Journal still opens the confirmation dialog.

**Spot-check**

`flutter test test/features/journal/ui/journal_screen_test.dart test/app/shell_test.dart test/app/app_test.dart`

- At 400px, Write opens a full-screen editor titled `New entry` with Close and Save and without Cancel. The editor covers the viewport. Close returns to Write.
- Above 600px, Write opens a dialog titled `New journal entry` with Cancel, Save, and Close. Cancel and Close each return to Write.
- Saving a subject, mood, and text from Write calls `save` once with `private: false`, then returns to Write.
- A thrown `save` leaves the editor up and shows `The entry could not be saved.`
- Shell tests listed above pass with Write in place of the `Journal` label. Dashboard, Archive, and sign-out behavior stay as they are.

**Done when:** acceptance criteria hold, and the commit-gate commands succeed with no warning or error, except the allowed Firebase emulator notice.

**Commit:** the commit-gate commands succeed with no warning or error, except the allowed Firebase emulator notice.
