## Summary

Reviewed PR #29 (*Redesign the sign-in screen*): ~1.1k lines across `login_screen.dart`, new `hypomnema_logo.dart`, `AppColors` info tokens, expanded widget tests, and new root `PLAN.md`. CI (`format_analyze_test`) is green. The layout contract, single-screen reset flow, themed snackbars, and test coverage (phone/desktop × light/dark, placement, dismissal) match the issue and PR description well. **Recommendation: approve**, with a few maintainability and documentation nits to address before or right after merge—nothing that blocks merge if you accept the current `PLAN.md` drift.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     3 |
| 📚 Documentation gaps                      |     1 |
| ✅ Positive feedback                       |     3 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     2 |
| **Total**                                  |     9 |

## Findings

### 🔒 Security concerns (immediate attention)

*(none)*

### ⚡ Performance issues/optimizations

*(none — [PERF-001] resolved in `39d756d`.)*

#### [PERF-001] — complete

**Issue:** `_standardLineHeight` built a `TextPainter` on every rebuild while a notice was visible.

**Resolution:** Removed text measurement; snackbars anchor with a fixed `_snackBarGap` (16px) under Forgot password. Tests assert `buttonBottom + 16`. No per-frame layout in the notice path.

### 🧹 Code cleanup and maintainability

#### [CLN-001] — complete

**Issue:** `login_screen.dart` mixed layout, auth, and three layers of custom snackbar UI.

**Resolution:** Uncommitted work moves `LoginNotice`, `LoginSnackBar`, and the anchored `RenderObject` stack into `lib/features/auth/ui/login_snackbar.dart`. `login_screen.dart` is ~474 lines and only composes `LoginSnackBar` with notice state and theme colors. Same feature-scoped split the review suggested.

[CLN-002]

**Issue:** `_measureAnchor` runs only once via a single `addPostFrameCallback`. If the anchor or overlay slot is not laid out on that frame, the method returns without rescheduling, so `_controller.forward()` never runs.

**Suggestion:** On failure, schedule another post-frame callback (with a small retry cap), or call `_measureAnchor` from `didChangeDependencies` when `anchorBottom` is still null.

**Why:** Reduces the risk of a silent failure where auth/reset feedback never appears even though `_notice` is set—especially on first paint or after a layout change.

[CLN-003]

**Issue:** User-facing strings and quotes (`_desktopQuote`, `_phoneQuote`, reset/sign-in messages) are duplicated in `login_screen_test.dart`.

**Suggestion:** Export test-visible constants from a small `login_screen_copy.dart` (or the screen library with `@visibleForTesting`), or import a single shared `auth_strings.dart` used by both production and tests.

**Why:** One source of truth prevents contract copy from drifting between UI and tests.

[CLN-004]

**Issue:** Snackbar anchor position is fixed at show time and does not update if the form moves (e.g. software keyboard, window resize, or scroll).

**Suggestion:** If product cares about keyboard overlap, listen for `WidgetsBindingObserver.didChangeMetrics` or remeasure when `MediaQuery.viewInsets` changes; otherwise document that notices are positioned for the static layout only.

**Why:** Clarifies expected behavior and avoids surprise misalignment on phone when the keyboard is open.

### 📚 Documentation gaps

[DOC-001]

**Issue:** New `PLAN.md` still describes the pre-change screen (reset form, inline errors) in the opening paragraph, lists STEP-002 as incomplete, and under **Decisions** says info colors stay on the sign-in screen and `AppTheme` is out of scope—while this PR adds `AppColors.info` / `infoContainer` and implements STEP-002 behavior.

**Suggestion:** Before merge, refresh `PLAN.md`: mark STEP-002 complete, update **Decisions** to record theme extension for info colors, and shorten the intro to past tense or remove the stale baseline paragraph.

**Why:** Contributors using `PLAN.md` per `CONTRIBUTING.md` should not see contradictions with the merged tree.

### ✅ Positive feedback

[POS-001]

**Issue:** *(n/a — positive)*

**Suggestion:** Widget tests go well beyond smoke checks: layout contract across 400/600/601/1200 widths, both themes, snackbar colors, horizontal centering, width-to-content, placement one line below Forgot password, enter animation, and timed dismissal.

**Why:** This gives strong regression protection for a UI-heavy change.

[POS-002]

**Issue:** *(n/a — positive)*

**Suggestion:** Promoting info banner colors to `AppColors` on `AppTheme` matches the PR intent and mirrors existing warning extension fields, with `app_test.dart` palette assertions updated accordingly.

**Why:** Keeps semantic colors centralized for later screens.

[POS-003]

**Issue:** *(n/a — positive)*

**Suggestion:** Custom notices use `Semantics(liveRegion: true)` on the snackbar material, which helps screen readers pick up auth and reset feedback without relying on `ScaffoldMessenger`.

**Why:** Aligns with accessible status messaging practices.

**Documentation:** https://www.w3.org/WAI/ARIA/apg/

### 🚨 Critical blockers

*(none)*

### 💭 Questions for discussion

[QST-001]

**Issue:** Should `PLAN.md` remain on `main` after the feature merges, or is it branch-only working notes that should be dropped or archived when #20 closes?

**Suggestion:** Align with team convention (e.g. keep for audit trail vs. delete to avoid stale plans).

**Why:** Avoids an accumulating set of out-of-date plans at repo root.

[QST-002]

**Issue:** The custom anchored snackbar is substantially more complex than `ScaffoldMessenger.showSnackBar` with margin/padding.

**Suggestion:** Confirm whether the custom `RenderShiftedBox` approach is a long-term pattern for the app or a one-off for login; if one-off, the extraction in [CLN-001] is enough; if long-term, consider promoting to `shared/ui`.

**Why:** Sets expectations for the next screen that needs “mock-accurate” notices.