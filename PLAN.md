# PLAN-6 — Follow the system light and dark setting

Issue: [#6](https://github.com/kensodemann-projects/hypomnema/issues/6) (OPEN). Related to [#1](https://github.com/kensodemann-projects/hypomnema/issues/1).

`MainApp.build` in `lib/main.dart` returns a `MaterialApp` from `package:material_ui/material_ui.dart` with only `home` set: a scaffold whose body is centered `Text('Hello World!')`. `theme`, `darkTheme`, and `themeMode` are omitted. `themeMode` defaults to `ThemeMode.system`, and `_themeBuilder` in `material_ui` selects `darkTheme` only when that argument is non-null. With `darkTheme` null, the resolved theme is `theme`, or `ThemeData()` when `theme` is also null. `ThemeData()` is the light theme, so a system dark setting still paints this app light. Android `values` and `values-night` already split the native launch theme; the Flutter theme does not follow that split.

**Decisions**

- Pass `theme: ThemeData.light()`, `darkTheme: ThemeData.dark()`, and `themeMode: ThemeMode.system` on this `MaterialApp`. `ThemeData` and `ThemeMode` come from `package:material_ui/material_ui.dart`.

**Out of scope**

- The login screen ([#3](https://github.com/kensodemann-projects/hypomnema/issues/3)), the authentication gate and sign-out ([#4](https://github.com/kensodemann-projects/hypomnema/issues/4)), and the Android and macOS shell placeholders ([#5](https://github.com/kensodemann-projects/hypomnema/issues/5)). This change does not add those screens. The theme stays on the root `MaterialApp`, so a later login screen or signed-in shell built under it follows the same system setting.
- An in-app light or dark control, high-contrast themes, and edits to the Android launch styles.

**File order**

| Order | Step       | Status | Files          |
| ----- | ---------- | ------ | -------------- |
| 1     | [STEP-001] |        | `lib/main.dart` |

**Commit gate** — the human commits. A spot-check does not replace the gate. From `CONTRIBUTING.md`:

```bash
dart format .
flutter analyze
flutter test
```

All three must succeed with no warning or error before that commit. This repository has no `test/` directory, and this issue does not ask for tests, so the step below does not add one. `flutter test` remains the test command; until a `test/` directory exists it exits because that directory is missing. CI leaves that step commented out for the same reason (`.github/workflows/flutter_ci.yml`).

## [STEP-001] Follow the system brightness on the root app

**Status:**

**Acceptance criteria:** With the platform brightness light, the theme under `MainApp` is light. With the platform brightness dark, that theme is dark. The home scaffold is unchanged. Widgets still come from `package:material_ui/material_ui.dart`.

**Files**

1. `lib/main.dart` — set the light theme, the dark theme, and system theme mode on `MaterialApp`.

**Change**

In `MainApp.build`, stop constructing a `const MaterialApp`. `ThemeData.light()` and `ThemeData.dark()` are factories, so the widget cannot stay const. Pass:

- `theme: ThemeData.light()`
- `darkTheme: ThemeData.dark()`
- `themeMode: ThemeMode.system`

Leave `home` as the existing scaffold and centered `Text('Hello World!')`. Do not add a `Theme` widget on the home, and do not branch on Android versus macOS. `MediaQuery.platformBrightness` is what `MaterialApp` already reads when `themeMode` is `ThemeMode.system`.

No test file. This area has no tests, and the issue does not ask for any.

**Done when:** the acceptance criteria hold, and build, test, and lint succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
