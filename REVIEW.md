# PR #52 — Use Material text roles across the app

**Reviewed:** resulting diff vs `main`  
**Recommendation:** Approve (comment-only follow-ups; no merge blockers)

## Summary

This change standardizes typography across journal, auth, and shared UI by binding copy to Material 3 `textTheme` roles instead of ad hoc `TextStyle` font sizes, and centralizes repeated chrome numbers in a new `AppMetrics` theme extension plus `SnackBarTheme` / `FAB` theme data. Error snackbars correctly move from `scheme.error` text on `errorContainer` to theme-driven `onErrorContainer`, which improves contrast. Tests were updated thoughtfully: metric comparisons use localized baseline `TextTheme`, and snackbar expectations assert resolved `DefaultTextStyle` rather than inline widget colors. The cursor rule documents the text-role practice for future UI work. Worth a quick visual pass on login and list/detail headings because several weights and sizes shift to role defaults by design.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     2 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     4 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     2 |
| **Total**                                  |     8 |

## Findings

### 🔒 Security concerns (immediate attention)

_No findings in this category._

### ⚡ Performance issues/optimizations

_No findings in this category._

### 🧹 Code cleanup and maintainability

**[CLN-001]**

**Issue:** `SnackBarThemeData.backgroundColor` and `contentTextStyle` are set globally on every `ThemeData` from `AppTheme`, so any future `SnackBar` that does not override colors will look like an error snackbar.

**Suggestion:** Add a short comment on `SnackBarTheme` or `_withComponentThemes` stating that only failure-path snackbars should use the stock `SnackBar` widget without overrides, or introduce a tiny helper (e.g. `showErrorSnackBar`) so call sites stay explicit.

```dart
// lib/core/theme/app_theme.dart — above snackBarTheme
// Global snack bar theme is tuned for failure toasts only. Success/info
// messages must override background/foreground or use a custom surface.
```

**Why:** Central theme defaults are easy to reuse accidentally; a one-line contract avoids regressions when new snackbars are added.

---

**[CLN-002]**

**Issue:** `journal_screen.dart` reads `Theme.of(context).extension<AppMetrics>()!` in several places, including nested builders where a `metrics` variable already exists in sibling methods (e.g. FAB `shape` uses a fresh `Theme.of` call inside `_phoneListPane`).

**Suggestion:** At the start of each layout helper (`_phoneListPane`, `_desktopListPane`, empty-state builder), capture `final metrics = theme.extension<AppMetrics>()!` once and pass or close over it.

**Why:** Fewer lookups, easier testing, and one place to handle a missing extension if themes ever diverge in tests.

### 📚 Documentation gaps

_No findings in this category._

### ✅ Positive feedback

**[POS-001]**

**Issue:** N/A (positive)

**Suggestion:** Error snackbars now rely on `onErrorContainer` via `SnackBarTheme` instead of `scheme.error` on an `errorContainer` background—a clear M3 contrast fix.

**Why:** Matches intended color pairs and aligns shell, journal load, and editor save behavior.

---

**[POS-002]**

**Issue:** N/A (positive)

**Suggestion:** `_withComponentThemes` uses `ThemeData.localize` to build `contentTextStyle` metrics, with a comment explaining why raw `theme.textTheme` is insufficient.

**Why:** Avoids subtle test/production drift on snackbar typography.

---

**[POS-003]**

**Issue:** N/A (positive)

**Suggestion:** `app_theme_test.dart` compares every text role’s metrics to a localized baseline theme and asserts `AppMetrics`, snackbar, and FAB theme fields.

**Why:** Locks the “roles stay default M3 metrics” decision so future theme edits do not silently retune the app.

---

**[POS-004]**

**Issue:** N/A (positive)

**Suggestion:** Removing `titleSize`, `headingSize`, and `subjectSize` from `EmptyState`, `JournalEntryList`, and `JournalEntryDetail` shrinks public APIs and pushes typographic decisions to the theme layer.

**Why:** Call sites become simpler and harder to diverge between phone and desktop.

### 🚨 Critical blockers

_No findings in this category._

### 💭 Questions for discussion

**[QST-001]**

**Issue:** Workspace layout guidance places cross-screen layout numbers in `lib/core/constants/` (e.g. `layout.dart`), while pane width, bar heights, and radii now live on `AppMetrics` in `app_theme.dart`.

**Suggestion:** Confirm that theme extensions are the preferred home for these numbers going forward, or split “breakpoint / layout policy” (`layout.dart`) from “visual metrics” (`AppMetrics`) in the cursor rule.

**Why:** Avoids two competing sources of truth for the same literals (380px pane width, 64px bar height, etc.).

---

**[QST-002]**

**Issue:** Sign-in still paints login error notices with `foreground: scheme.error` on `errorContainer` via `LoginSnackBar`, while Material snackbars in this PR use `onErrorContainer`.

**Suggestion:** If contrast parity matters everywhere, a small follow-up could switch login error foreground to `onErrorContainer` (info notices can stay on `AppColors`).

**Why:** Users may perceive inconsistent error styling between auth and the signed-in shell even though `LoginSnackBar` was explicitly out of scope for #47.