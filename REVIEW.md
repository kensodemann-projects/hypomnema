# Pull request review: #23 — apply the app theme

Repository: `kensodemann-projects/hypomnema`  
Branch: `19-apply-the-indigo-app-theme` → `main`

## Summary

This change introduces a dedicated `AppTheme` with indigo light/dark `ColorScheme` values mapped from the UI contract, wires it into `MainApp`, and extends widget tests to assert every contract color plus `ThemeMode.system`. Scope is focused and aligns with issue #19; `make check`-relevant tests pass locally (`flutter test test/main_test.dart`, 13/13). **Recommendation: approve**, with optional follow-ups to reduce duplicated color literals in tests and to confirm whether `PLAN.md` should land on `main`.

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

### 🧹 Code cleanup and maintainability

**[CLN-001]**

**Status:** won't-do

**Issue:** Contract colors are defined twice: once in `lib/ui/app_theme.dart` and again as `_lightPalette` / `_darkPalette` in `test/main_test.dart` (~90 lines of identical `Color` literals).

**Suggestion:** Treat `AppTheme.light` and `AppTheme.dark` as the single source of truth in tests. For example, compare the resolved widget theme to the `MaterialApp` theme for the platform brightness under test, or add a small helper that asserts two `ThemeData` instances match on contract fields:

```dart
void expectContractThemesMatch(ThemeData actual, ThemeData expected) {
  _expectContractColors(actual, _paletteFromTheme(expected));
}

// Or avoid a palette type entirely:
void expectSchemeMatches(ThemeData a, ThemeData b) {
  expect(a.colorScheme.primary, b.colorScheme.primary);
  // ... same fields as today ...
  expect(a.scaffoldBackgroundColor, b.scaffoldBackgroundColor);
}
```

In `expectMainAppTheme`, resolve `expected` from `materialApp.theme` / `materialApp.darkTheme` based on `brightness` instead of parallel const tables.

**Why:** Any future palette tweak requires editing two files; duplicated tables are a common source of drift even with strong tests.

---

**[CLN-002]**

**Status:** complete

**Issue:** `expectMainAppTheme` reads the app-level `ThemeData` via `Theme.of(tester.element(find.byType(ScaffoldMessenger)))`, which depends on `MaterialApp` always inserting a `ScaffoldMessenger` in a stable place.

**Suggestion:** The test already holds `materialApp` from `tester.widget<MaterialApp>(...)`. For light/dark platform brightness tests, the effective theme is `materialApp.theme` or `materialApp.darkTheme` before resolution through descendants—compare the shell theme to that instance directly.

**Why:** Fewer assumptions about widget-tree shape; easier for the next reader to see that shell and `MaterialApp` configs should match.

---

### ✅ Positive feedback

**[POS-001]**

**Issue:** N/A

**Suggestion:** `AppTheme` is a clear, minimal API (`light` / `dark` getters), uses `package:material_ui/material_ui.dart` per project conventions, mirrors the written contract (explicit `ColorScheme` fields, separate `scaffoldBackgroundColor`, secondary aliased to primary as documented), and leaves shell/login widgets unchanged while still picking up `surfaceContainerHigh` and `error`.

**Why:** The production diff is small and purposeful; behavior is easy to audit against `PLAN.md` and `docs/ui-mockups`.

---

**[POS-002]**

**Issue:** N/A

**Suggestion:** Brightness tests now assert the full palette and `ThemeMode.system`, not only `Theme.brightness`. Login-related tests remain on their own `MaterialApp`, which matches the documented out-of-scope boundary.

**Why:** Regression coverage matches the acceptance criteria in the plan step.

---

### 💭 Questions for discussion

**[QST-001]**

**Issue:** The PR adds root `PLAN.md` (marked complete for STEP-001). `CONTRIBUTING.md` describes `PLAN.md` as part of branch workflow but does not state whether it is merged to `main` or removed before merge.

**Suggestion:** Confirm team intent: keep `PLAN.md` on `main` as implementation history, rotate/rename per issue, or drop it from the PR before merge.

**Why:** Avoids accumulating stale plans on the default branch if the intent is ephemeral branch-only artifacts.

---

**[QST-002]**

**Issue:** Login UI is explicitly out of scope; its preview/tests still use default `ThemeData`, so sign-in will not show indigo tokens until a follow-up wires `AppTheme` there.

**Suggestion:** Track a follow-up task (or note on #17) to apply `AppTheme` to `login_screen.dart` and its widget tests so auth matches the rest of the app.

**Why:** Users hit login before the themed shell; visual consistency may matter for the first impression even though functional tests pass today.