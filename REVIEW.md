# PR #45 — Write a journal entry (re-review)

Reviewed: resulting diff on `35-write-a-journal-entry` vs `main` (issue #35), second pass as of the latest branch tip. `PLAN.md` ignored per merge practice. Root `REVIEW.md` is merge workflow artifact and is stripped before merge (see `CONTRIBUTING.md`).

## Summary

The branch delivers the #35 contract: Journal shows **Write**, opens a responsive `JournalEditor`, saves a new public entry through `JournalEntryRepository`, and keeps Dashboard/Archive/sign-out behavior intact. Since the first review, follow-ups landed: shared `FakeJournalEntryRepository` in `test/helpers/`, shell navigation refactored to `_NavDestination` + `WidgetBuilder`, and save-in-flight behavior now disables Close/Cancel (with tests) instead of queuing a silent dismiss on failure.

No open product or test gaps remain for this issue scope. **Recommendation: approve.**

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     0 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     4 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     0 |
| **Total**                                  |     4 |

## Findings

### Security

(No findings.)

### Performance

(No findings.)

### Code cleanup and maintainability

(No open findings.)

### Documentation

(No findings.)

### Positive feedback

**[POS-001]**

**Issue:** N/A

**Suggestion:** `JournalEditor` exposes `onSubmit`; `JournalScreen` maps that to `repository.save(..., private: false)`. Tests use `_Submissions` or `FakeJournalEntryRepository` without Firebase.

**Why:** Clean UI/data boundary and straightforward widget/integration coverage.

---

**[POS-002]**

**Issue:** N/A

**Suggestion:** Editor and screen tests cover phone/desktop chrome, trimmed-field validation, double-save suppression, failure snackbar colors, multiline text, and the Write → save → return path with `private: false`.

**Why:** Strong regression net for a UI-heavy slice and for later editor features (#37–#39).

---

**[POS-003]**

**Issue:** N/A

**Suggestion:** `Shell._destinations()` pairs each tab’s label/icon with a `WidgetBuilder` and builds `destinations[_selectedIndex].build(context)`. Phone and desktop scaffolds receive pre-built `NavigationDestination` / `NavigationRailDestination` lists from the same source.

**Why:** Nav copy no longer controls which screen mounts; adding tabs stays localized.

---

**[POS-004]**

**Issue:** N/A

**Suggestion:** While `_saving` is true, `_PhoneEditor` and `_DesktopEditor` receive `onDismiss: null`, so Close and Cancel cannot pop during an in-flight save. Tests assert disabled controls and that a failed save still shows the snackbar on the editor.

**Why:** Resolves the earlier dismiss-during-failure edge case without surprising the user.

### Critical blockers

(No findings.)

### Questions for discussion

(No open findings.)

## Addressed since initial review

| Tag | Resolution |
| --- | ---------- |
| CLN-001 | `test/helpers/fake_journal_entry_repository.dart`; app, shell, and journal screen tests reuse `FakeJournalEntryRepository` (`1d8eefa`). Cursor rule documents the pattern. |
| CLN-002 | Shell `_NavDestination` + index-selected `build` callbacks (`c2f07f3`). |
| CLN-003 | Accepted as-is: `Dialog` `insetPadding` (32px vertical) keeps the dialog within the viewport; scrollable body matches mock behavior. |
| QST-001 | Close/Cancel disabled during save; failed save shows snackbar on the editor (see `POS-004`). |