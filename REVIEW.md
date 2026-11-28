# Review: Edit a journal entry within 24 hours

PR: https://github.com/kensodemann-projects/hypomnema/pull/53

## Summary

This review covers the resulting diff against `main` for the 24-hour journal edit window. `PLAN.md` is ignored. Request changes. The shared window, the phone and desktop edit affordances, and the tests match the issue: Edit and the note appear only while `createdAt` is inside 24 hours, saving goes through `update`, and the original time stays. Two code issues should be fixed before merge. The phone detail drops the entry it already has and waits on a second `watch()` with no error handler, so every phone open starts blank and a stream error is uncaught. The "Editable until" day word says `tomorrow` for any later calendar day, which is wrong when a daylight-saving spring-forward puts the deadline two local days ahead. One question is whether a detail or editor left open past the deadline should still be able to save.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     2 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     2 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     1 |
| **Total**                                  |     **5** |

## Findings

### 🧹 Code cleanup and maintainability

[CLN-001]

**Issue:** Every phone entry now opens through `_PhoneEntryScreen`, which starts with `_entry == null` and fills it only after a new `repository.watch()` event. The route already received the `JournalEntry` in `_openEntry`. The first frames are a bar with an empty title and no body. `listen` also has no `onError`. The list subscription handles watch failures; this second subscription reports them as uncaught zone errors and leaves the blank page up. `Navigator.pop` from the detail pops the navigator's top route, so a snapshot that omits the id while the editor is open dismisses the editor and then stops (`_closed`), leaving the detail in place.

**Suggestion:** Pass the entry that was opened, paint it immediately, and keep the subscription for later updates. Handle errors on the subscription, and pop only while this route is the current one.

```dart
class _PhoneEntryScreen extends StatefulWidget {
  const _PhoneEntryScreen({
    required this.repository,
    required this.entry,
    required this.clock,
    required this.onEdit,
  });

  final JournalEntryRepository repository;
  final JournalEntry entry;
  final DateTime Function() clock;
  final void Function(BuildContext context, {JournalEntry? entry}) onEdit;
}

class _PhoneEntryScreenState extends State<_PhoneEntryScreen> {
  StreamSubscription<List<JournalEntry>>? _subscription;
  late JournalEntry _entry;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _subscription = widget.repository.watch().listen(
      _onEntries,
      onError: _onWatchError,
    );
  }

  void _onEntries(List<JournalEntry> entries) {
    if (!mounted) {
      return;
    }
    for (final candidate in entries) {
      if (candidate.id == widget.entry.id) {
        setState(() => _entry = candidate);
        return;
      }
    }
    if (_closed || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _closed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onWatchError(Object error, StackTrace stackTrace) {
    // Keep _entry on screen. The list listener already reports the failure.
  }
}
```

Add a widget test that pumps a single frame after opening the phone detail and still finds the subject. The current tests use `pumpAndSettle`, so they pass after the blank gap.

**Why:** Opening an entry used to render the object already in hand. The extra `watch()` is what lets the detail pick up a save, and the first event is asynchronous on both the fake and Firestore, so the empty frame is visible on every phone open, including entries outside the window. An `onError` keeps a bad snapshot from becoming an uncaught error on a route the list already knows how to handle. Checking `isCurrent` keeps a missing-entry pop from closing the editor that was pushed on top of the detail.

[CLN-002]

**Issue:** `journalEditableUntilNote` labels every deadline that is not on today's local calendar day as `tomorrow`. A 24-hour absolute duration crosses at most one local midnight when the offset stays put. When the local offset springs forward during the window, the deadline's local calendar day can be two days after `now`. In `America/New_York`, an entry created at 11:30 PM EST on 2026-03-07 has its deadline at 12:30 AM EDT on 2026-03-09. Viewed at 11:45 PM that same Saturday, the window is still open and the note says `Editable until 12:30 AM tomorrow`. Tomorrow is Sunday; the deadline is Monday. The clock time is the real local deadline. The day word is a day early. The same branch is what a fixed-offset zone never hits, so a UTC CI run stays green.

**Suggestion:** Choose the day word from the local calendar distance, and cover that choice without depending on the host zone.

```dart
String? journalEditableUntilNote({
  required DateTime createdAt,
  required DateTime now,
}) {
  if (!isWithinEditWindow(createdAt: createdAt, now: now)) {
    return null;
  }
  final deadline = editWindowDeadline(createdAt).toLocal();
  final day = _deadlineDayWord(deadline, now.toLocal());
  return 'Editable until ${_time(deadline)} $day';
}

String _deadlineDayWord(DateTime deadlineLocal, DateTime nowLocal) {
  final today = _date(nowLocal);
  final deadlineDay = _date(deadlineLocal);
  if (_sameDay(deadlineDay, today)) {
    return 'today';
  }
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  if (_sameDay(deadlineDay, tomorrow)) {
    return 'tomorrow';
  }
  final month = _monthAbbreviations[deadlineDay.month - 1];
  return '$month ${deadlineDay.day}';
}
```

Test `_deadlineDayWord` with the three local dates directly: same day, next day, and two days ahead (`March 7` versus `March 9` → `Mar 9`).

**Why:** The sentence is the feature's statement of the deadline. `today` and `tomorrow` match the mock-ups for the usual one-midnight span. The extra branch keeps a spring-forward evening from naming the wrong day, and a pure date comparison can be tested in any host zone.

### ✅ Positive feedback

[POS-001]

**Issue:** The 24-hour rule lives in one place other features can call, and the journal sentence stays with the other journal display strings.

**Suggestion:** Keep `editWindowDeadline` and `isWithinEditWindow` in `lib/core/utils/edit_window.dart`, and keep `journalEditableUntilNote` next to `journalDetailWhen`. The window compares UTC instants, stays open through the deadline, and closes one microsecond later. Tests cover a UTC creation, a local creation, and both the inclusive deadline and the instant after it.

**Why:** Later features can share the same window without copying the comparison, and the journal copy can change without moving the rule. `JournalEntry.revise` and `FirestoreJournalEntryRepository.update` still leave `createdAt` and `localDateTime` alone, and the screen tests show the original when-string after a save.

[POS-002]

**Issue:** Phone and desktop are both specified and tested, including the case the window is meant to get right.

**Suggestion:** Keep the paired cases: open versus closed window, `createdAt` inside the window while `localDateTime` is old and the reverse, light and dark scheme colors, a private entry staying private, one `update` and no `save`, and no Delete control. `_BarIconButton` gives Back and the phone Edit the same 48×48 target.

**Why:** The acceptance criteria are about both form factors, both themes, and the creation timestamp rather than the wall clock. Those tests lock that behavior in. The desktop Edit colors follow the outlined-button mock (`primary` on `outline`), and the note uses `bodySmall` in `onSurfaceVariant` with a 16-pixel schedule icon, matching the mock's note treatment on both form factors.

### 💭 Questions for discussion

[QST-001]

**Issue:** The window is read when the detail builds. Nothing schedules a rebuild at the deadline, and the edit `submit` calls `repository.update` without `isWithinEditWindow`. A detail left open, or an editor opened just before the deadline, can still save after 24 hours. Issue #37 says security rules leave the window alone, so this is the client boundary.

**Suggestion:** Confirm the intended gate: Edit is shown or hidden from the clock at build time, and a save already in progress always calls `update`. If an open detail should lose Edit as the deadline passes, the detail needs a timer that rebuilds at `editWindowDeadline`, and the save path needs the same check before `update`.

**Why:** The acceptance criteria say Edit is available only inside the window and absent after it. The current code meets that for a detail built on either side of the deadline. It leaves the already-open case unspecified, and the tests never advance the clock while the route is up.
