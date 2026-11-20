# Pull Request Review: #27 — Adopt a feature-first lib and test layout

**Branch:** `refactor-file-structure` → `main`  
**Scope:** Structural refactor — renames and extracts `MainApp`, auth gate, and signed-in shell from `main.dart` into `lib/app/`, moves auth and shared UI under `features/` and `shared/`, mirrors paths under `test/`, and documents the layout in `.cursor/rules/hypomnema.mdc`. No intentional behavior changes.

## Summary

This PR is a clean feature-first reorganization: entry-point bootstrap stays in `main.dart`, composition lives in `app/`, and imports are updated consistently across lib and test. Widget tests were renamed and retargeted to import `app.dart` and `shell.dart` instead of `main.dart`, which keeps Firebase initialization out of test harnesses. All 49 tests pass locally. **Recommendation: approve.** Remaining notes are optional follow-ups around file boundaries and shared test utilities, not merge blockers.

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
| **Total**                                  |     5 |

## Findings

### Security

_No findings._

### Performance

_No findings._

### Code cleanup and maintainability

**[CLN-001]**

**Issue:** `lib/app/shell.dart` combines `AuthGate` (auth stream routing and login vs shell selection) with `Shell`, `DesktopScaffold`, and `PhoneScaffold` (signed-in chrome). The PR description positions `shell.dart` as signed-in shell and scaffolds; the auth gate is a separate concern.

**Suggestion:** Split auth routing into its own module under `app/`, for example `lib/app/auth_gate.dart`, and keep `shell.dart` focused on layout scaffolds only.

```dart
// lib/app/auth_gate.dart
class AuthGate extends StatelessWidget { /* ... */ }

// lib/app/shell.dart — Shell, DesktopScaffold, PhoneScaffold only
```

**Why:** Smaller files make ownership clearer as more features land, and `shell.dart` stays aligned with its stated purpose in project rules.

**[CLN-002]**

**Issue:** `setLogicalViewportSize` is copy-pasted identically in `test/app/app_test.dart`, `test/features/auth/ui/login_screen_test.dart`, and `test/shared/ui/confirmation_dialog_test.dart`.

**Suggestion:** Introduce a shared helper (for example `test/helpers/viewport.dart`) and import it from the mirrored test paths.

**Why:** The new test layout is a natural time to deduplicate; one change to viewport setup then applies everywhere.

### Documentation

_No findings._

### Positive feedback

**[POS-001]**

**Issue:** N/A — positive observation.

**Suggestion:** The `.cursor/rules/hypomnema.mdc` tree diagram, mirror rule for `test/`, and placement examples (`login_screen` vs repository paths) give agents and contributors a single source of truth for where new code belongs.

**Why:** Structural refactors often regress without enforced conventions; encoding the layout in rules reduces drift.

**[POS-002]**

**Issue:** N/A — positive observation.

**Suggestion:** Moving `MainApp` to `lib/app/app.dart` and having `test/app/app_test.dart` import `package:hypomnema/app/app.dart` (plus `shell.dart` for scaffold types) instead of `main.dart` preserves the prior test coverage while isolating widget tests from Firebase emulator setup in `main()`.

**Why:** Keeps tests faster and less brittle as bootstrap logic grows.

### Critical blockers

_No findings._

### Questions for discussion

**[QST-001]**

**Issue:** `AuthGate` lives in `app/` but directly depends on `features/auth` (`LoginScreen`, `AuthService`). As routing grows (additional features, deep links, `go_router`), it is unclear whether composition stays in `app/` or moves into a dedicated navigation layer.

**Suggestion:** Align on a rule of thumb: `app/` owns cross-feature composition and top-level gates; feature folders own screens and feature-specific navigation. Confirm that matches the intended end state before adding a router.

**Why:** Early agreement avoids splitting or re-moving auth routing when the second feature arrives.