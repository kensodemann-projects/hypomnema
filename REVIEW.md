# Pull request review — [#30 Add the navigation shell and confirm sign-out](https://github.com/kensodemann-projects/hypomnema/pull/30)

## Summary

Reviewed the combined diff for PR #30 (~767 additions): new root `PLAN.md`, refactored `lib/app/shell.dart` (responsive `NavigationRail` / `NavigationBar`, shared destination state, confirmation-gated sign-out, error snackbar), and expanded `test/app/app_test.dart` coverage. Static analysis on the touched Dart files reports no issues; all 23 tests in `test/app/app_test.dart` pass locally.

**Recommendation: Approve** — implementation matches the stated contract, handles `mounted` after async work, and tests exercise phone/desktop parity, resize behavior, and sign-out flows thoroughly. Remaining notes are maintainability, documentation hygiene, and optional hardening rather than blockers.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     2 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     2 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     2 |
| **Total**                                  |     6 |

## Findings

### ✅ Positive feedback

**[POS-001]**

**Issue:** N/A (commendation).

**Suggestion:** Keep the current `Shell` structure: a single `StatefulWidget` owns `_selectedIndex`, passes callbacks into public `PhoneScaffold` / `DesktopScaffold`, and switches at the existing `> 600` breakpoint via `LayoutBuilder`.

**Why:** Selection survives layout changes without duplicating state, and scaffolds stay testable in isolation. This aligns with feature-first composition in `app/` and sets up cleanly for real Dashboard/Journal/Archive screens later.

**[POS-002]**

**Issue:** N/A (commendation).

**Suggestion:** Retain the sign-out test helpers (`_openSignOutDialog`, `expectSignOutDialog`, `expectSignOutFailureSnackBar`) and the matrix of phone/desktop scenarios (dialog open, cancel, confirm, `AuthException` + snackbar lifetime).

**Why:** These assertions lock the UI copy, confirmation styling, destination preservation, and error presentation to the PLAN contract. They will catch regressions when auth or dialog code changes.

### 🧹 Code cleanup and maintainability

**[CLN-001]**

**Issue:** `test/app/app_test.dart` is approaching 950+ lines and now mixes long-lived theme contract tests with a large block of shell and sign-out navigation tests.

**Suggestion:** When the next shell change lands, extract shell-only helpers and widget tests into `test/app/shell_test.dart` (or `test/app/shell/shell_test.dart` if you split helpers), leaving `app_test.dart` focused on `MainApp` auth-gate and top-level wiring.

**Why:** Smaller, topic-focused test files reduce merge conflict surface and make failures easier to triage without changing what you ship in this PR.

**[CLN-002]**

**Issue:** Desktop sign-out is a custom `InkWell` + `Column` in `_SignOutRailButton`, while phone sign-out is a `NavigationDestination`. Behavior is equivalent in tests, but accessibility and focus behavior may differ between form factors.

**Suggestion:** Consider wrapping the rail control with `Semantics(button: true, label: 'Sign out')` or using a `TextButton` / `IconButton` styled to match the rail trailing slot so screen readers and keyboard users get consistent affordances.

**Why:** Material `NavigationDestination` on phone inherits navigation semantics; a plain `InkWell` may not announce as a button without extra semantics.

**Documentation:** [WAI-ARIA practices](https://www.w3.org/WAI/ARIA/apg/)

### 💭 Questions for discussion

**[QST-001]**

**Issue:** This PR adds `PLAN.md` at the repository root with step status marked complete.

**Suggestion:** Confirm team policy: should `PLAN.md` merge to `main` as a permanent record, or should it be removed before merge (similar to uncommitted `INTENT.md` in CONTRIBUTING)?

**Why:** CONTRIBUTORS may assume only production code and tests land on `main`; clarifying avoids accumulating one PLAN per closed issue at the root.

**[QST-002]**

**Issue:** `_signOut` in `shell.dart` catches only `AuthException` after a confirmed sign-out; any other error from `authService.signOut()` would propagate uncaught.

**Suggestion:** If `AuthService` is guaranteed to map all failures to `AuthException`, a one-line comment above the `try`/`on AuthException` block would document that invariant. If not guaranteed, consider a broad catch that shows the same snackbar or logs in debug.

**Why:** Prevents silent crashes in production if Firebase or the service implementation adds a new failure mode later.