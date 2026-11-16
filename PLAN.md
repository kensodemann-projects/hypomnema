# PLAN-19 — Apply the indigo app theme

Issue: [#19](https://github.com/kensodemann-projects/hypomnema/issues/19) (OPEN). Related to [#17](https://github.com/kensodemann-projects/hypomnema/issues/17).

`MainApp` in `lib/main.dart` builds a `MaterialApp` with `ThemeData.light()`, `ThemeData.dark()`, and `ThemeMode.system`. `test/main_test.dart` already checks that platform brightness selects the light or dark theme. The desktop shell reads `colorScheme.surfaceContainerHigh`. The sign-in screen reads `colorScheme.error`. Neither screen defines the palette.

## Decisions

- The light and dark `ThemeData` values live in `lib/ui/app_theme.dart`. `MainApp` applies them and keeps `ThemeMode.system`.
- Stylesheet tokens in `docs/ui-mockups/desktop/shared.css` map onto the `ColorScheme` fields of the same name. `--background` is `ThemeData.scaffoldBackgroundColor`, because `ThemeData` otherwise paints the scaffold with `colorScheme.surface`.
- `secondary` and `onSecondary` use the primary and on-primary colors. The stylesheet has no `--secondary` or `--on-secondary` token, and those two fields are required. `ColorScheme` then falls back to them for tertiary.
- Roles the stylesheet does not name stay unset, so `ColorScheme` uses its own fallbacks. Do not call `ColorScheme.fromSeed`.

## Out of scope

- Restyling `lib/ui/auth/login_screen.dart`, including its preview `MaterialApp`.
- Replacing the placeholder phone and desktop shells.
- Stylesheet tokens with no `ColorScheme` field: `--primary-hover`, `--success`, `--success-container`, `--warning`, `--warning-container`, `--info`, `--info-container`, the mood scale, and `--shadow`.

## Contract

`ThemeMode.system` stays in place. Platform brightness selects the matching theme. Colors are `Color(0xAARRGGBB)`.

| Role | Light | Dark |
| --- | --- | --- |
| primary | `0xFF4A55C8` | `0xFFBCC2FF` |
| onPrimary | `0xFFFFFFFF` | `0xFF1A237A` |
| primaryContainer | `0xFFDFE0FF` | `0xFF323D9F` |
| onPrimaryContainer | `0xFF0E1260` | `0xFFDFE0FF` |
| secondary | same as primary | same as primary |
| onSecondary | same as onPrimary | same as onPrimary |
| secondaryContainer | `0xFFE2E1F5` | `0xFF44455A` |
| onSecondaryContainer | `0xFF1A1B2C` | `0xFFE2E1F5` |
| surface | `0xFFFFFFFF` | `0xFF1C1C22` |
| surfaceContainerLow | `0xFFF8F8FD` | `0xFF202027` |
| surfaceContainer | `0xFFF1F1F8` | `0xFF25252C` |
| surfaceContainerHigh | `0xFFE9E9F2` | `0xFF2E2E36` |
| onSurface | `0xFF1B1B21` | `0xFFE4E1E9` |
| onSurfaceVariant | `0xFF46464F` | `0xFFC7C5D0` |
| outline | `0xFF777680` | `0xFF918F9A` |
| outlineVariant | `0xFFC7C5D0` | `0xFF46464F` |
| error | `0xFFBA1A1A` | `0xFFFFB4AB` |
| onError | `0xFFFFFFFF` | `0xFF690005` |
| errorContainer | `0xFFFFDAD6` | `0xFF93000A` |
| onErrorContainer | `0xFF410002` | `0xFFFFDAD6` |
| scrim | `0x61000000` | `0x99000000` |
| scaffoldBackgroundColor | `0xFFF4F4FA` | `0xFF131318` |

## File order

| Order | Step | Status | Files |
| ----- | ---- | ------ | ----- |
| 1 | [STEP-001] | | `lib/ui/app_theme.dart`, then `lib/main.dart`, then `test/main_test.dart` |

## Commit gate

The human commits. A spot-check does not replace the gate. `make check` already runs the test target.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit.

## [STEP-001] Apply the indigo light and dark themes

**Status:**

**Acceptance criteria:** `MainApp` uses the contract colors for light and dark, and platform brightness still selects which one is shown.

**Files**

1. `lib/ui/app_theme.dart` — light and dark `ThemeData` for the contract.
2. `lib/main.dart` — `MainApp` applies those themes and keeps `ThemeMode.system`.
3. `test/main_test.dart` — the existing light and dark `MainApp` tests also assert the contract colors and `ThemeMode.system`.

**Change**

Add `AppTheme` with `light` and `dark` getters. Each builds `ThemeData` from a `ColorScheme` of the matching brightness plus `scaffoldBackgroundColor`. Set only the contract roles. Import widgets from `package:material_ui/material_ui.dart`.

In `MainApp.build`, set `theme` to `AppTheme.light` and `darkTheme` to `AppTheme.dark`. Leave `themeMode` as `ThemeMode.system`. Leave `LoginScreen`, `PhoneScaffold`, and `DesktopScaffold` as they are. The desktop rail already reads `surfaceContainerHigh`, and the sign-in error text already reads `colorScheme.error`, so both pick up the new theme through `MainApp`.

Extend the two brightness tests in `test/main_test.dart`. After the shell is showing, read `Theme.of` for that shell and the `MaterialApp`. Assert `themeMode` is `ThemeMode.system`, `brightness` is the platform brightness already under test, and every contract role matches that brightness column. Leave the login-screen tests on their own default `MaterialApp`.

**Spot-check**

```bash
flutter test test/main_test.dart
```

- The light and dark `MainApp` tests pass, including the contract color assertions.
- The shell, auth-gate, and sign-out tests in that file still pass.

**Done when:** `MainApp` uses the contract colors for light and dark, platform brightness still selects which one is shown, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
