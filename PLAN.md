# PLAN-31 — Desktop Sign out button

Issue: [#31](https://github.com/kensodemann-projects/hypomnema/issues/31) (OPEN).

`DesktopScaffold` in `lib/app/shell.dart` places `_SignOutRailButton` in `NavigationRail.trailing` with `trailingAtBottom: true`. That control is a `Column` with a `Divider` and an `InkWell` keyed `shell-sign-out`. The ink well calls `onSignOut`, which is `_ShellState._signOut`: it opens the existing confirmation dialog and leaves `_selectedIndex` unchanged. The ink well can take keyboard focus, and its semantics node has a tap action, but that node is not marked as a button. `PhoneScaffold` keeps Sign out as the last `NavigationDestination` in the bottom `NavigationBar`. `test/app/shell_test.dart` taps `shell-sign-out` on both layouts and checks the dialog and the selected destination.

**Decisions**

- Desktop Sign out is a `TextButton` in `_SignOutRailButton`. It keeps the divider above it, the logout icon stacked over the visible text `Sign out`, and `Key('shell-sign-out')`.
- The button uses the ambient foreground color, vertical padding of 12, and a shrink-wrapped minimum size so it stays the rail's trailing control.
- The logout icon has no semantic label, so the accessible name is the visible text `Sign out`.

**Out of scope**

- The confirmation dialog's copy, buttons, and failure snackbar, and `AuthService.signOut`.
- The rail destinations Dashboard, Journal, and Archive, and which destination is selected.
- The phone bottom bar.

**Contract**

- The desktop Sign out semantics label is `Sign out`, and the node is a button.
- Keyboard activation opens the dialog titled `Sign out?`, with message `You'll need your email and password to sign back in.` and confirm label `Sign out`.
- `NavigationRail.selectedIndex` stays on the destination selected before activation.

**File order**

| Order | Step       | Status | Files                                              |
| ----- | ---------- | ------ | -------------------------------------------------- |
| 1     | [STEP-001] |        | `lib/app/shell.dart`, then `test/app/shell_test.dart` |

**Commit gate**

The human commits. A spot-check does not replace the gate. Every commit-gate command must succeed with no warning or error before that commit.

```bash
make web
make check
```

## [STEP-001] Make desktop Sign out a focusable button

**Status:**

**Acceptance criteria:** On the desktop rail, Sign out is a button named `Sign out` that can take keyboard focus and open the existing confirmation dialog from the keyboard. The selected destination stays unchanged. Sign out stays below the divider at the bottom of the rail. Phone Sign out stays the last `NavigationDestination` in the bottom bar.

**Files**

1. `lib/app/shell.dart` — replace the rail `InkWell` with a `TextButton`.
2. `test/app/shell_test.dart` — assert the button semantics, keyboard activation, and divider placement.

**Change**

In `_SignOutRailButton`, keep the outer `Column` and the `Divider`. Replace the `InkWell` with a `TextButton` keyed `shell-sign-out`. Its `onPressed` calls `onSignOut`. Its child stays the logout `Icon`, a 4-pixel gap, and `Text('Sign out')`. Leave the icon without a semantic label.

Style the button with `TextButton.styleFrom`: foreground color from `IconTheme.of(context).color`, padding `EdgeInsets.symmetric(vertical: 12)`, `minimumSize: Size.zero`, and `tapTargetSize: MaterialTapTargetSize.shrinkWrap`. Leave `NavigationRail.trailing`, `trailingAtBottom`, and `PhoneScaffold` as they are. Leave `_signOut` as it is, so activation still opens the confirmation dialog and does not change `_selectedIndex`.

In `test/app/shell_test.dart`:

- In the existing desktop layout test (`Given a width of 601, when the shell builds, then Dashboard is selected`), assert that the rail `Divider` is above `Key('shell-sign-out')`.
- Add a desktop test that enables semantics with `tester.ensureSemantics()`, reads the semantics node for `Key('shell-sign-out')`, and expects label `Sign out`, `SemanticsFlag.isButton`, `SemanticsFlag.isFocusable`, and `SemanticsAction.tap`. Expect that key's widget to be a `TextButton`.
- Add a desktop test that selects Journal, requests focus on the `Focus` descendant of `Key('shell-sign-out')`, expects that node to have focus, then sends `LogicalKeyboardKey.enter`. The existing sign-out dialog is open, `signOutCalls` is 0, the content is Journal, and `shellSelectedIndex` is 1.
- Leave the phone tests in place. They already expect four destinations and a last `NavigationDestination` labeled `Sign out`.

`test/app/app_test.dart` already taps `Key('shell-sign-out')` and confirms sign-out. The key stays on the control, so that file stays unchanged.

**Spot-check**

```bash
flutter test test/app/shell_test.dart
```

- The new desktop semantics test shows a button named `Sign out`.
- The new keyboard test opens the confirmation dialog with Journal still selected.
- The existing desktop layout test shows the divider above Sign out, and the phone tests still show Sign out as the last bottom-bar destination.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
