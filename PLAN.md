# PLAN-5 — Show distinct Android and macOS shell placeholders

Issue: [#5](https://github.com/kensodemann-projects/hypomnema/issues/5) (OPEN). Related to [#1](https://github.com/kensodemann-projects/hypomnema/issues/1).

`MainApp.build` in `lib/main.dart` returns a `MaterialApp` whose `home` is a `Scaffold` with a centered `Text('Hello World!')`. `theme`, `darkTheme`, and `themeMode` are already set. The home does not read window size. `test/main_test.dart` finds `Hello World!` and checks that `Theme` brightness follows the platform brightness. UI widgets already come from `package:material_ui/material_ui.dart`.

**Decisions**

- The shell picks its layout from the width `LayoutBuilder` gives the home, not from `TargetPlatform`. Width greater than 600 logical pixels is the desktop layout. Width of 600 or less is the phone layout. A narrow macOS window shows the phone shell. A wide Android window shows the desktop shell.
- The phone shell is a `Scaffold` with an `AppBar` that has no title. The body centers the text `Phone`.
- The desktop shell is a `Scaffold` with no app bar. The body is a `Row`: a side panel 72 logical pixels wide, then the remaining space centering the text `Desktop`. The panel has no text. Its color is `ColorScheme.surfaceContainerHigh`, and it uses `Key('shell-side-panel')`.
- The shell is a public `Shell` widget in `lib/main.dart`, and `MainApp` sets `home` to it.

**Out of scope**

- Email-and-password sign-in and forgot-password ([#3](https://github.com/kensodemann-projects/hypomnema/issues/3)).
- The authentication gate and sign-out ([#4](https://github.com/kensodemann-projects/hypomnema/issues/4)).
- `theme`, `darkTheme`, and `themeMode` on `MaterialApp`.
- Firebase initialization, navigation destinations, and notes.

**Contract**

- Width of 600 or less: one `AppBar` with no title, one `Phone` text, no `Desktop` text, and no `shell-side-panel`.
- Width greater than 600: no `AppBar`, one `Desktop` text, no `Phone` text, and one `shell-side-panel` that is 72 logical pixels wide.

**File order**

| Order | Step       | Status | Files                                      |
| ----- | ---------- | ------ | ------------------------------------------ |
| 1     | [STEP-001] | complete | `lib/main.dart`, then `test/main_test.dart` |

**Commit gate** — the human commits. A spot-check does not replace the gate. The repository has no separate build command. `make check` runs these three, and CI runs the same three. All three must succeed with no warning or error before that commit.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## [STEP-001] Switch the shell on window width

**Status:** complete

**Acceptance criteria:** A window 600 logical pixels wide or narrower shows the phone shell. A wider window shows the desktop shell. The strings and structure match the contract.

**Files**

1. `lib/main.dart` — replace the `Hello World!` home with `Shell`.
2. `test/main_test.dart` — assert both widths, and keep the brightness check on the visible placeholder.

**Change**

Add `Shell` in `lib/main.dart` and set `MainApp`'s `home` to `const Shell()`. Leave `theme`, `darkTheme`, and `themeMode` as they are. Import nothing new: `LayoutBuilder`, `Scaffold`, `AppBar`, `Center`, `Text`, `Row`, `Expanded`, `SizedBox`, `ColoredBox`, `Key`, and `Theme` come from `package:material_ui/material_ui.dart`.

`Shell.build` returns a `LayoutBuilder`. When `constraints.maxWidth > 600`, return the desktop scaffold. Otherwise return the phone scaffold.

The phone scaffold has an `AppBar` with no `title` and a body of `Center(child: Text('Phone'))`.

The desktop scaffold has no app bar. Its body is a `Row`. The first child is a `SizedBox` of width 72 and height `double.infinity`, keyed `Key('shell-side-panel')`, whose child is a `ColoredBox` of `Theme.of(context).colorScheme.surfaceContainerHigh`. The second child is `Expanded(child: Center(child: Text('Desktop')))`.

In `test/main_test.dart`, set `tester.view.devicePixelRatio` to `1` and set `tester.view.physicalSize` for each case. Reset both in `addTearDown`. The default test surface is 800 by 600, which is already the desktop layout, so every assertion sets the size explicitly.

For each of `Brightness.light` and `Brightness.dark`:

- Size `Size(400, 800)`: one `Phone` text, no `Desktop` text, one `AppBar`, no `shell-side-panel`. `Theme.of` that `Phone` text has the same brightness.
- Size `Size(1200, 800)`: one `Desktop` text, no `Phone` text, no `AppBar`, one `shell-side-panel`. `Theme.of` that `Desktop` text has the same brightness.

Remove the `Hello World!` finder.

**Spot-check**

`flutter test test/main_test.dart`

- Both widths show the contract text and chrome, and both brightness values still match the theme.

**Done when:** acceptance criteria hold, and build, test, and lint succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
