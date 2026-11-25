# PLAN-36 — List and read journal entries

Issue: [#36](https://github.com/kensodemann-projects/hypomnema/issues/36) (OPEN). Related to [#32](https://github.com/kensodemann-projects/hypomnema/issues/32).

`JournalScreen` in `lib/features/journal/ui/journal_screen.dart` is a centered Write button (`journal-write`). That button opens `JournalEditor` full screen when the window width is 600 or less, and in a dialog when the window is wider. `JournalEntryRepository` in `lib/features/journal/data/journal_entry_repository.dart` can `save` and `update` documents under `users/{uid}/journalEntries`, and it has no way to read them back. `JournalEntry` in `lib/features/journal/domain/journal_entry.dart` only builds an entry from a clock instant. The shell treats that Write button as the Journal destination on phone and desktop, including when the repository has no entries (`test/app/shell_test.dart`). `expectPhoneShellExists` still requires the shell tree to contain no `AppBar`.

## Decisions

- Older weeks use `Week of Nov 8`: the Sunday that starts the week, abbreviated like the row dates. Add the year only when that Sunday is in a different year than the screen clock (`Week of Dec 28, 2025`). The current Sunday–Saturday week is `This week`. The previous one is `Last week`.
- `JournalEntryRepository.watch` is a `Stream<List<JournalEntry>>` of the signed-in user's entries, `createdAt` descending. Labels and week groups use each entry's `localDateTime` wall clock, compared with the screen clock's local calendar date. Weeks run Sunday through Saturday.
- The screen clock defaults to `DateTime.now` and can be injected. Fixtures set `localDateTime` through `JournalEntry.restore`, so labels do not depend on the host time zone.
- Desktop selects the newest entry when nothing is selected. A later snapshot keeps the selected id while that entry is still present, and selects the newest entry when it is not. Phone opens an entry on a full-screen route and does not mark a selected row.
- Desktop is a window wider than 600, read from `MediaQuery.sizeOf`, the same rule `_openEditor` and `Shell` already use.
- The phone list title and the phone entry bar are custom bars, matching `JournalEditor`'s phone bar, so the shell still has no `AppBar`.
- Reading text uses the theme font at the mock-up sizes. This step adds no font package.
- Before the first `watch` event, the body is a progress indicator. An empty list is the empty journal. A `watch` error shows one floating snackbar, `The entries could not be loaded.`, with `errorContainer` background and `error` text, and shows neither the list nor the empty journal.
- Blank lines split the entry text into paragraphs. A single newline stays inside a paragraph.
- There is no tab bar. The screen title is `Journal`.

## Out of scope

- Edit, Make Private, Make Public, Show Content, and the "Editable until" note.
- The private-entry lock and the hidden subject or text. A private entry shows its stored subject and text.
- The Journal header pill, and the Entries, Mood Trend, and Journaling Goal tabs.
- I'm Stuck prompts. The empty-state sentence names them; this task does not open a prompt.
- An italic first line in place of a subject. `JournalEntry` requires a subject.

## Copy and dates

Empty journal, both layouts:

- Title: `Start your journal`
- Message: `Write about anything: how today went, something on your mind, or one good thing. If you're not sure where to start, I'm Stuck gives you a prompt.`
- Action: `Write your first entry`

Desktop list pane when empty: `No entries yet.`

Headings from `groupJournalEntries` stay in this casing. The list draws them in uppercase.

With the screen clock on Saturday, November 14, 2026:

| `localDateTime` | Row | Heading |
| --- | --- | --- |
| `2026-11-14T08:02:00` | `Today · 8:02 AM` | `This week` |
| `2026-11-13T21:40:00` | `Yesterday · 9:40 PM` | `This week` |
| `2026-11-12T22:15:00` | `Thu, Nov 12 · 10:15 PM` | `This week` |
| `2026-11-08T18:12:00` | `Sun, Nov 8 · 6:12 PM` | `This week` |
| `2026-11-06T21:50:00` | `Fri, Nov 6 · 9:50 PM` | `Last week` |
| `2026-10-25T09:00:00` | `Sun, Oct 25 · 9:00 AM` | `Week of Oct 25` |
| `2025-12-28T09:00:00` | `Sun, Dec 28 · 9:00 AM` | `Week of Dec 28, 2025` |

`2026-11-14T08:02:00` in the detail: desktop `Saturday, November 14, 2026 · 8:02 AM`; phone `Saturday, November 14 · 8:02 AM`; phone bar `Sat, Nov 14`.

`00:00` is `12:00 AM`. `12:00` is `12:00 PM`. Hours have no leading zero. Minutes are two digits. `AM` and `PM` are uppercase.

With the clock on Monday, November 16, 2026, Sunday November 15 is `Yesterday` and `This week`. Saturday November 14 is `Last week` and its row uses `Sat, Nov 14`, not `Yesterday`.

## File order

| Order | Step | Status | Files |
| ----- | ---- | ------ | ----- |
| 1 | [STEP-001] | complete | `lib/features/journal/domain/journal_entry.dart`, then `test/features/journal/domain/journal_entry_test.dart`, then `lib/features/journal/data/journal_entry_repository.dart`, then `test/features/journal/data/journal_entry_repository_test.dart`, then `test/helpers/fake_journal_entry_repository.dart` |
| 2 | [STEP-002] | complete | `lib/features/journal/domain/journal_list.dart`, then `test/features/journal/domain/journal_list_test.dart` |
| 3 | [STEP-003] | complete | `lib/shared/ui/empty_state.dart`, then `test/shared/ui/empty_state_test.dart` |
| 4 | [STEP-004] | complete | `test/helpers/fake_journal_entry_repository.dart`, then `lib/features/journal/ui/journal_entry_list.dart`, then `lib/features/journal/ui/journal_entry_detail.dart`, then `lib/features/journal/ui/journal_screen.dart`, then `test/features/journal/ui/journal_screen_test.dart`, then `test/app/shell_test.dart` |
| 5 | [STEP-005] | | `lib/features/journal/ui/journal_entry_list.dart`, then `lib/features/journal/ui/journal_entry_detail.dart`, then `lib/features/journal/ui/journal_screen.dart`, then `test/features/journal/ui/journal_screen_test.dart` |

## Commit gate

The human commits. A spot-check does not replace the gate.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit. The one notice that may appear, and does not fail the gate, is the Firebase CLI notice that another emulator suite is already running for project `kws-hypomnema`. The rules tests start their own emulator on port 8180 while the dev suite stays on port 8080.

## [STEP-001] Read stored entries newest first

**Status:** complete

**Acceptance criteria:** `watch` emits the signed-in user's stored entries, newest `createdAt` first, rebuilt with the stored `localDateTime` and `createdAt`. A signed-out `watch` emits `JournalEntryRepositoryException` and does not read Firestore. `save` and `update` keep their current behavior.

**Files**

1. `lib/features/journal/domain/journal_entry.dart` — add `JournalEntry.restore`.
2. `test/features/journal/domain/journal_entry_test.dart` — `restore` keeps the stored wall-clock string and a UTC `createdAt`. A blank subject, a mood outside 1–5, or an impossible `localDateTime` throws `InvalidJournalEntryException`.
3. `lib/features/journal/data/journal_entry_repository.dart` — add `watch` to `JournalEntryRepository` and `FirestoreJournalEntryRepository`.
4. `test/features/journal/data/journal_entry_repository_test.dart` — empty `watch` emits an empty list; saved entries emit newest first and a later save appears on the open stream; a document under another user is absent; a document `restore` rejects errors the stream; a signed-out `watch` errors with `JournalEntryRepositoryException` and leaves Firestore empty.
5. `test/helpers/fake_journal_entry_repository.dart` — implement `watch`, publish the stored list on listen, and publish again after a successful `save` or `update`. A failed `save` still records the attempt and stores nothing.

**Change**

Add `JournalEntry.restore({id, subject, mood, text, private, localDateTime, createdAt})`. Trim subject and text. Reject an empty id, an empty trimmed subject or text, and a mood outside 1–5, using `InvalidJournalEntryException`. Accept `localDateTime` only in the form `_formatLocalDateTime` already writes, `YYYY-MM-DDTHH:mm:ss`, when the date and time are a real calendar value. Keep that string as stored. Store `createdAt.toUtc()`.

`watch` on a signed-out user returns `Stream.error(const JournalEntryRepositoryException())` and does not query. Otherwise listen to `users/{uid}/journalEntries` with `orderBy('createdAt', descending: true)`. Map each snapshot through `JournalEntry.restore`, reading `subject`, `mood` as an int, `text`, `private`, `localDateTime`, and `createdAt` as a `Timestamp`. A document that cannot be restored errors that snapshot's stream event.

The fake keeps the existing `saves` list and `saveError` behavior. Successful `save` stores the `JournalEntry` it returns, with distinct ids when `save` is called more than once. `watch` yields the current list, then later successful writes.

**Spot-check**

```bash
flutter test test/features/journal/domain/journal_entry_test.dart test/features/journal/data/journal_entry_repository_test.dart
```

- Those tests pass, including the new `watch` and `restore` cases. Existing `save` and `update` cases still pass.

**Done when:** the acceptance criteria hold, and the commit gate succeeds with no warning or error other than the emulator notice recorded under Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than that emulator notice.

## [STEP-002] Group entries and format their dates

**Status:** complete

**Acceptance criteria:** Row labels, detail labels, the phone bar title, and week headings match the Copy and dates section. Groups follow newest-first input order. A week with no entries produces no heading.

**Files**

1. `lib/features/journal/domain/journal_list.dart` — `JournalWeekGroup`, `groupJournalEntries`, `journalRowWhen`, `journalDetailWhen`, and `journalEntryBarTitle`.
2. `test/features/journal/domain/journal_list_test.dart` — the table, the Monday week-boundary case, `12:00 AM` and `12:00 PM`, desktop and phone detail strings, the phone bar title, and an empty list.

**Change**

Parse `localDateTime` with `DateTime.parse` so the value stays a local wall clock. Compare calendar dates of that value and `now.toLocal()`.

`journalRowWhen(entry, now)` uses `Today`, then `Yesterday`, then `Thu, Nov 12`, each followed by ` · ` and the time. `journalDetailWhen(entry, includeYear: true)` is `Saturday, November 14, 2026 · 8:02 AM`. `includeYear: false` omits `, 2026`. `journalEntryBarTitle(entry)` is `Sat, Nov 14`.

`groupJournalEntries` does not sort. It walks the newest-first list, starts a group when the Sunday of `localDateTime` changes, and appends each entry to that group. Sunday is the start of the week (`DateTime.weekday` Sunday is 7). The heading is `This week` when that Sunday is the Sunday of `now`, `Last week` when it is seven days earlier, and otherwise `Week of` plus the Sunday's abbreviated month and day, with `,` and the year only when the Sunday's year differs from `now`'s year. English month and weekday names are fixed in this file.

**Spot-check**

```bash
flutter test test/features/journal/domain/journal_list_test.dart
```

- Every label and heading in Copy and dates passes, including the Monday boundary and the empty list.

**Done when:** the acceptance criteria hold, and the commit gate succeeds with no warning or error other than the emulator notice recorded under Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than that emulator notice.

## [STEP-003] Add the shared empty state

**Status:** complete

**Acceptance criteria:** `EmptyState` shows a primary icon, a title, a message, and a filled action. The action calls `onAction`. Light and dark themes take title, message, and icon colors from the theme.

**Files**

1. `lib/shared/ui/empty_state.dart` — `EmptyState`, imported from `package:material_ui/material_ui.dart`.
2. `test/shared/ui/empty_state_test.dart` — sample title, message, and action label render; the action tap fires once; in `AppTheme.light` and `AppTheme.dark` the title uses `onSurface`, the message uses `onSurfaceVariant`, and the icon uses `primary` at 80% opacity. The action is a `FilledButton`.

**Change**

`EmptyState` takes `icon`, `iconSize`, `title`, `titleSize`, `message`, `actionLabel`, `actionIcon`, and `onAction`. Lay them out in a centered column with a 10-pixel gap. The title is weight 600. The message is 14 pixels, centered, and uses `onSurfaceVariant`. The icon color is the theme `primary` at 80% opacity. The action is `FilledButton.icon` when `actionIcon` is set. The widget owns this layout only. Journal copy stays in the journal screen. Callers supply padding and max width.

**Spot-check**

```bash
flutter test test/shared/ui/empty_state_test.dart
```

- The sample empty state renders, the action fires, and both themes use the scheme colors above.

**Done when:** the acceptance criteria hold, and the commit gate succeeds with no warning or error other than the emulator notice recorded under Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than that emulator notice.

## [STEP-004] Show the phone list, entry, and empty journal

**Status:** complete

**Acceptance criteria:** At a window width of 600 or less, an empty journal shows the shared empty state with the journal copy and no floating Write button. `Write your first entry` opens the existing full-screen editor. With entries, the list is newest first under uppercase week headings, each row shows the mood swatch, subject, and row label, and the floating Write button opens the editor. Tapping a row opens the entry full screen with the large mood swatch, the phone date and time, the full subject, and the full text, including a private entry's subject and text. Back returns to the list. A successful save from the empty journal replaces the empty state with that entry and shows the floating button. The desktop branch of `JournalScreen` stays the centered Write button.

**Files**

1. `test/helpers/fake_journal_entry_repository.dart` — a held first `watch` event, and `watchError`, so the screen can show loading and the load snackbar.
2. `lib/features/journal/ui/journal_entry_list.dart` — week headings and tappable rows.
3. `lib/features/journal/ui/journal_entry_detail.dart` — mood, when, subject, and paragraphs for the phone entry.
4. `lib/features/journal/ui/journal_screen.dart` — phone list, empty state, floating Write, entry route, and load handling. Desktop stays the centered button.
5. `test/features/journal/ui/journal_screen_test.dart` — phone empty copy and the absent floating button; `Write your first entry` still saves a trimmed public entry and then shows that subject with the floating button; a failed save still leaves the editor open with the existing failure snackbar; a seeded newest-first list across `This week` and `Last week` shows uppercase headings and row labels for a fixed clock of November 14, 2026; a private entry's row shows its subject; tapping a row shows the phone detail strings and text, and back returns to the list; loading hides `Start your journal`; a `watch` error shows `The entries could not be loaded.` and hides both the list and the empty journal; light and dark themes color the row border with `outlineVariant`, the heading with `onSurfaceVariant`, and the floating button with `primaryContainer` and `onPrimaryContainer`. Existing desktop Write tests still open the dialog from `journal-write`.
6. `test/app/shell_test.dart` — phone Journal assertions expect `Start your journal` and `Write your first entry`, and expect no `journal-write`. Desktop Journal assertions still expect `journal-write`. The resize test expects the phone empty journal at 400 and `journal-write` at 601. `expectPhoneShellExists` still finds no `AppBar`.

**Change**

Widgets come from `package:material_ui/material_ui.dart`. `JournalScreen` gains `DateTime Function() clock`, defaulting to `DateTime.now`.

Phone, `MediaQuery.sizeOf(context).width <= 600`: a column whose first child is a bar of min height 64, surface background, and left padding 16. Its title is `Journal` at 22 pixels, weight 400, key `journal-title`. The bar is not an `AppBar`. The expanded child subscribes to `repository.watch()`.

Waiting for the first event shows a progress indicator, key `journal-loading`. An error shows the snackbar described in Decisions and an otherwise empty body. Build the snackbar once per error. An empty list shows `EmptyState`, key `journal-empty`, with `Icons.edit_note` at 44 pixels, title size 17, the journal copy, action icon `Icons.edit`, and `onAction` calling the existing `_openEditor`. Center it with padding 40 by 16. Omit the floating button.

A non-empty list shows `JournalEntryList`, key `journal-list`, padded from LTRB 16, 8, 16, 24, with 8 pixels between children. Headings use the group heading's uppercase form, 12 pixels, weight 600, letter spacing 0.72, `onSurfaceVariant`, padding from LTRB 4, 8, 4, 0. Each row, key `journal-entry-$id`, is a tappable surface: padding 10 by 12, gap 12, radius 12, border 1 `outlineVariant`, a regular `MoodSwatch`, the subject at weight 500, one line, ellipsis, and `journalRowWhen` at 12 pixels in `onSurfaceVariant`. Place `FloatingActionButton.extended` at the bottom-right of the body, 16 pixels in from those edges, key `journal-write`, icon `Icons.edit`, label `Write`, background `primaryContainer`, foreground `onPrimaryContainer`, corner radius 16. It calls `_openEditor`.

Tapping a row pushes a `MaterialPageRoute` on the root navigator. That route is a `Scaffold`, key `journal-entry-screen`, surface background. Its bar matches the phone editor bar: min height 64, an arrow-back button of 48 pixels, key `journal-back`, and `journalEntryBarTitle` at 18 pixels, weight 400, one line, ellipsis. The body uses `JournalEntryDetail`: padding from LTRB 16, 4, 16, 24, gap 14, a large `MoodSwatch`, `journalDetailWhen(entry, includeYear: false)` at 13 pixels in `onSurfaceVariant`, the subject at 22 pixels, weight 400, height 1.25, then the paragraphs. Paragraphs are the trimmed pieces of `text` split on a blank line, shown at 16 pixels with height 1.75 and 14 pixels between them. Popping the route returns to the list.

Keep the width `> 600` branch as the current centered `FilledButton` until [STEP-005].

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_screen_test.dart test/app/shell_test.dart
```

- Phone empty, list, detail, save, load, and error cases pass in the themes those tests cover. Desktop Write still opens and dismisses the editor. Shell phone Journal shows the empty copy, and shell desktop Journal still shows `journal-write`.

**Done when:** the acceptance criteria hold, and the commit gate succeeds with no warning or error other than the emulator notice recorded under Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than that emulator notice.

## [STEP-005] Show the desktop list beside the selected entry

**Status:**

**Acceptance criteria:** Above a window width of 600, the header shows `Journal` and Write, and Write opens the existing editor dialog. The list sits in a 380-pixel pane beside the selected entry. The newest entry is selected on first load. Choosing another row keeps that entry selected when a newer one is saved. The detail shows the large mood swatch, the desktop date and time including the year, the full subject, and the full text. An empty journal keeps header Write, shows `No entries yet.` in the list pane, and shows the shared empty state in the detail pane. Both Write actions open the editor. Light and dark themes use the scheme colors below. Phone behavior from [STEP-004] stays.

**Files**

1. `lib/features/journal/ui/journal_entry_list.dart` — selected-row colors, and heading size and letter spacing supplied by the caller.
2. `lib/features/journal/ui/journal_entry_detail.dart` — subject size supplied by the caller, and a card around the paragraphs when the desktop pane asks for it.
3. `lib/features/journal/ui/journal_screen.dart` — replace the centered desktop button with the header, split panes, selection, and desktop empty panes.
4. `test/features/journal/ui/journal_screen_test.dart` — header Write still opens the dialog and Cancel or Close returns to it; empty desktop shows `No entries yet.`, the shared empty copy, and header `journal-write`, with no floating button; `Write your first entry` and header Write both open the editor; seeded entries show the newest subject in the detail with `Saturday, November 14, 2026 · 8:02 AM` and the year; the selected row uses `primaryContainer`, `onPrimaryContainer`, and a 2-pixel `primary` border; tapping an older row shows that subject; saving a newer entry leaves the older detail in place and adds the new subject at the top of the list; a private entry shows its subject and text; light and dark themes both follow those scheme colors; the detail card uses `surface` and an `outlineVariant` border. The phone tests from [STEP-004] still pass.

**Change**

Desktop is a column. The header, key `journal-header`, has min height 72, padding from LTRB 28, 18, 28, 14, surface background, and a 1-pixel bottom border in `outlineVariant`. The title is `Journal` at 24 pixels, weight 400, letter spacing -0.2, key `journal-title`. `FilledButton.icon`, key `journal-write`, icon `Icons.edit`, label `Write`, calls `_openEditor`.

Under the header, a row fills the rest. The list pane, key `journal-list-pane`, is 380 pixels wide, color `surfaceContainerLow`, padding 16, with a 1-pixel right border in `outlineVariant`. The detail pane, key `journal-detail-pane`, is expanded, padding from LTRB 32, 24, 32, 48.

Empty list pane: centered `No entries yet.`, key `journal-list-empty`, `onSurfaceVariant`, padding 32 by 16. Empty detail pane: center an `EmptyState` with `Icons.edit_note` at 48, title size 18, message max width 380, the journal copy, and action icon `Icons.edit`. That action and the header button both call `_openEditor`.

Non-empty list pane: the same `JournalEntryList`, with desktop heading metrics of 11 pixels and letter spacing 0.88, padding from LTRB 4, 8, 4, 2. Pass `selectedId`. The selected row uses padding 9 by 11, a 2-pixel `primary` border, `primaryContainer` background, and `onPrimaryContainer` for the subject and the when label. The mood swatch keeps its own colors. Tapping a row sets the selected id.

The detail pane uses `JournalEntryDetail` for the selected entry: large `MoodSwatch`, `journalDetailWhen(entry, includeYear: true)`, subject at 26 pixels, weight 400, letter spacing -0.3, height 1.25, and the paragraphs inside a card of surface color, 1-pixel `outlineVariant` border, radius 16, and padding 32 by 28. The card's max width is 760 and it is centered horizontally. Gap between the head and the card is 14.

Track selection in `JournalScreen` state. On each snapshot, keep the selected id when that entry is still in the list. When the id is missing, or nothing is selected yet, select `entries.first`. Phone ignores `selectedId`.

Shell desktop tests keep finding `journal-write` on the header, including the empty journal, so `test/app/shell_test.dart` needs no change unless a new assertion fails.

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_screen_test.dart test/app/shell_test.dart
```

- Desktop empty, selection, save, detail, and theme cases pass. Phone cases from [STEP-004] pass. The shell still finds Journal's Write button on desktop and the empty journal on phone.

**Done when:** the acceptance criteria hold, and the commit gate succeeds with no warning or error other than the emulator notice recorded under Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than that emulator notice.
