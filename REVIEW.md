# PR #46 — List and read journal entries

## Summary

This PR delivers journal list and read flows end-to-end: `watch` on the repository, domain date/week grouping, shared `EmptyState`, phone list and full-screen detail, and a desktop master–detail layout with selection retention on save. Tests are thorough at domain, repository, widget, and shell levels. **Recommendation: approve (comment-only)** — nothing blocks merge; the main follow-ups are build-time side effects in `JournalScreen`, aligning typography and chrome with the theme (including your planned text-style task), and a few optional polish items.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     3 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     4 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     2 |
| **Total**                                  |     9 |

## Findings

### 🧹 Code cleanup and maintainability

[CLN-001]

**Issue:** `_selectedIdFor` assigns `_selectedId` while the `StreamBuilder` is building (`_listPane` and `_selectedDetail` both call it). That makes the build method impure and can surprise future refactors (e.g. calling `setState` nearby or extracting widgets that assume stable selection during a single frame).

**Suggestion:** Resolve selection when the stream delivers data, not while building children:

```dart
// In StreamBuilder builder, after `final entries = snapshot.data!`:
if (MediaQuery.sizeOf(context).width > 600) {
  final id = _selectedId;
  if (entries.isEmpty) {
    _selectedId = null;
  } else if (id == null || !entries.any((e) => e.id == id)) {
    _selectedId = entries.first.id;
  }
}
```

Then pass `_selectedId` into the list and detail without mutating inside `_selectedIdFor`.

**Why:** Keeps Flutter’s “build is a pure function of state” rule and avoids subtle ordering bugs if list and detail diverge on the same frame.

[CLN-002]

**Issue:** `_reportWatchError()` runs from inside the `StreamBuilder` `builder` when `snapshot.hasError`, setting `_reportedWatchError` synchronously during build (the snackbar correctly uses a post-frame callback, but the flag still updates in `build`).

**Suggestion:** Prefer `StreamBuilder`’s listener pattern, a dedicated `StreamSubscription` in `initState`, or `ref.listen`-style handling: on error, schedule the snackbar once outside `build`.

**Why:** Side effects in `build` are easy to duplicate on rebuilds and conflict with framework guidance, even when a guard flag usually works.

[CLN-003]

**Issue:** The phone entry route reimplements the custom 64px bar (back affordance, title typography) in `journal_screen.dart`, parallel to patterns already in `journal_editor.dart`.

**Suggestion:** When you tackle theme/chrome consistency, consider a small shared widget (e.g. `JournalPhoneBar`) used by the editor and entry screen, with title style driven from the theme.

**Why:** One place to adjust bar height, padding, and title style when mock-ups or accessibility requirements change.

### ✅ Positive feedback

[POS-001]

**Issue:** N/A

**Suggestion:** `journal_list.dart` keeps formatting and week grouping in pure domain code with a detailed unit test table (row labels, headings, Monday boundary, year rules). UI stays thin and testable.

**Why:** This is the right split for date copy that will keep growing.

[POS-002]

**Issue:** N/A

**Suggestion:** Repository `watch` tests cover empty list, ordering, live updates, cross-user isolation, invalid documents, and signed-out errors. That matches the screen’s reliance on a single stream.

**Why:** Reduces risk when Firestore shape or auth edge cases change.

[POS-003]

**Issue:** N/A

**Suggestion:** `journal_screen_test.dart` exercises phone and desktop layouts, loading hold, watch errors, selection after save, themes on list chrome, and empty states; `shell_test.dart` was updated for the phone empty journal.

**Why:** Responsive behavior is validated where regressions would hurt most.

[POS-004]

**Issue:** N/A

**Suggestion:** `FakeJournalEntryRepository` gained `holdWatch`, `watchError`, and broadcast updates—good hooks for async UI without fighting Firestore in every widget test.

**Why:** Keeps screen tests fast and deterministic.

### 💭 Questions for discussion

[QST-001]

**Issue:** A single invalid Firestore document causes `watch` to error the entire stream (`_read` throws inside `.map`), which shows the global load failure UI and hides valid entries.

**Suggestion:** Confirm this matches product intent for corrupt or manually edited data. If not, a future change could map per-doc failures to skipped rows plus logging, or a “partial load” state.

**Why:** Trade-off between data integrity signaling and resilience when one bad doc exists among many good ones.

[QST-002]

**Issue:** List rows are `InkWell` taps without custom `Semantics` (subject + date are separate `Text` nodes). Screen readers may not announce the row as one actionable journal entry.

**Suggestion:** Wrap the row (or use `MergeSemantics` / `semanticLabel`) so accessibility gets e.g. “Today’s meeting, Today · 8:02 AM, button”.

**Why:** Journal list is a primary navigation surface on both form factors.

---

## Theme consistency (for your planned text-style task)

These are intentionally **comment-only** for this PR; they align with favoring `ThemeData.textTheme` (and optional `ThemeExtension`s) over ad hoc `TextStyle(fontSize: …)` and caller-supplied `titleSize` / `headingSize`.

| Area | Current pattern | Theme direction |
| ---- | ----------------- | ------------- |
| Screen titles | Phone 22px, desktop 24px, weight 400, custom letter spacing on desktop | `textTheme.headlineSmall` / `titleLarge` variants in `AppTheme` |
| Week section headings | 11–12px, w600, letter spacing 0.72 / 0.88, uppercase in widget | `labelSmall` + `letterSpacing` in theme, or a `JournalTextStyles` extension |
| Row subject / when | w500 subject; 12px when label | `titleSmall` + `labelSmall` with `onSurfaceVariant` |
| Detail “when” line | 13px `onSurfaceVariant` | `labelMedium` |
| Detail subject | 22px phone / 26px desktop, height 1.25 | Distinct headline roles rather than `subjectSize` parameters |
| Body paragraphs | 16px, height 1.75 | `bodyLarge` with explicit height in theme |
| Empty state | `titleSize` param; message hardcoded 14px | Empty-state title/message from text theme; drop per-call `titleSize` when roles are fixed |
| Phone entry bar title | 18px w400 | Same as editor bar title role |
| “No entries yet.” | Default text style + `onSurfaceVariant` color only | `bodyMedium` + color |
| Error snackbar | `TextStyle(color: scheme.error)` on `errorContainer` | `SnackBarTheme` / `onErrorContainer` for contrast per Material 3 |
| Phone FAB | Manual `primaryContainer` / `onPrimaryContainer` | `ThemeData.floatingActionButtonTheme` or `FloatingActionButtonThemeData` tied to color scheme |
| Empty state icon | `primary.withValues(alpha: 0.8)` | Optional opacity in theme extension or shared “muted primary” role |
| Layout chrome | Pane width 380, header 72 / bar 64, card radius 16 | Not typography, but a `JournalLayout` or `ThemeExtension` could hold pane width, radii, and border widths so list/detail/card match editor |

`AppTheme` today sets `ColorScheme` and `AppColors` but leaves `textTheme` at defaults; this PR’s journal UI is the first large consumer of fixed pixel sizes from the mock-ups—making it a good anchor for the follow-up task.