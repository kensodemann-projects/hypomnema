# PLAN-18 — Add the shared confirmation dialog

Issue: [#18](https://github.com/kensodemann-projects/hypomnema/issues/18) (OPEN). Related to [#17](https://github.com/kensodemann-projects/hypomnema/issues/17).

There is no shared confirmation dialog. `Shell.build` and `LoginScreen.build` both choose the desktop layout when `constraints.maxWidth > 600` and the phone layout otherwise. This plan adds the dialog those later actions can call. It does not change `Shell`, `_SignOutButton`, or `LoginScreen`.

**Decisions**

- `showConfirmationDialog` in `lib/ui/confirmation_dialog.dart` returns `Future<bool>`. The confirm action closes the dialog and completes `true`. Cancel and a scrim tap close it and complete `false`.
- The confirm label is an argument. Cancel's label is `Cancel`.
- `ConfirmationStyle.normal` is a `FilledButton` in `ColorScheme.primary` and `ColorScheme.onPrimary`. `ConfirmationStyle.danger` is a `FilledButton` in `ColorScheme.error` and `ColorScheme.onError`.
- A null or empty warning is omitted. Any other warning is one plain string in a banner, with `Icons.warning`, beside the text.
- The dialog uses the same breakpoint as `Shell` and `LoginScreen`: desktop when `maxWidth > 600`, phone otherwise.
- Warning-banner colors stay in the dialog and follow `ThemeData.brightness`. Light uses `#8A5000` on `#FFDDB3`. Dark uses `#FFB86B` on `#6A3C00`. These are the mock-up `--warning` and `--warning-container` tokens. `AppTheme` stays unchanged.

**Out of scope**

- Sign-out copy, wiring Sign out to this dialog, and signing the person out. Those belong to the navigation shell task.
- The leading action icon on the sign-out, delete, and archive mock-ups.
- Entry, slip, resource, and other dialogs that are not this confirmation.
- Warning colors on `AppTheme`.

**Contract**

- Cancel reads `Cancel`, closes the dialog, and completes `false`.
- The confirm action reads the caller's label, closes the dialog, and completes `true`.
- The warning banner is visible only when the warning is non-empty, and its text is that warning.
- Phone (`maxWidth <= 600`): dialog width is the viewport width minus 48, title size is 20, and the content gap is 14.
- Desktop (`maxWidth > 600`): dialog width is 440, title size is 22, and the content gap is 16.
- Both layouts center the title, use a 14px message in `ColorScheme.onSurfaceVariant`, inset the dialog by 24 on every side, and use a 28px corner radius.

**File order**

| Order | Step       | Status | Files                                                                      |
| ----- | ---------- | ------ | -------------------------------------------------------------------------- |
| 1     | [STEP-001] |        | `lib/ui/confirmation_dialog.dart`, then `test/ui/confirmation_dialog_test.dart` |

**Commit gate** — the human commits. A spot-check does not replace the gate. `make check` already runs `test`.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit.

## [STEP-001] Add the shared confirmation dialog

**Status:**

**Acceptance criteria:** The dialog shows a title, a message, Cancel, and a confirm action, plus a warning only when one is provided. Cancel closes it with `false`. The confirm action closes it with `true` in either the normal style or the danger style. Phone and desktop each use the contract layout.

**Files**

1. `lib/ui/confirmation_dialog.dart` — add `ConfirmationStyle`, `ConfirmationDialog`, and `showConfirmationDialog`.
2. `test/ui/confirmation_dialog_test.dart` — widget tests for the contract.

**Change**

Import UI widgets from `package:material_ui/material_ui.dart`.

Add `enum ConfirmationStyle { normal, danger }`.

Add `Future<bool> showConfirmationDialog` with required `BuildContext context`, `String title`, `String message`, `String confirmLabel`, and `ConfirmationStyle style`, plus optional `String? warning`. It calls `showDialog<bool>` with `ConfirmationDialog` and returns the popped value, or `false` when the value is null. Leave the barrier dismissible so a scrim tap pops null.

`ConfirmationDialog` is the `AlertDialog`. Give it `Key('confirmation-dialog')`, `insetPadding` of 24 on every side, and a 28px rounded rectangle. Read the incoming constraints with `LayoutBuilder`. Above 600, set the dialog width to 440, the title size to 22, and the content gap to 16. At 600 and below, leave the width to the insets, set the title size to 20, and the content gap to 14.

The title is `Text` with `Key('confirmation-title')`, centered, font weight 400, and the layout's title size. The content is a column with the layout's gap: a 14px message with `Key('confirmation-message')` in `ColorScheme.onSurfaceVariant`, then the warning banner when `warning` is non-null and not empty. The banner has `Key('confirmation-warning')`, radius 12, padding 12 by 16, a 12px gap, 13px text, and `Icons.warning` at size 20. Its foreground and background are the warning colors in **Decisions**.

Actions align to the end. Cancel is a `TextButton` with `Key('confirmation-cancel')` and the label `Cancel`; it pops `false`. Confirm is a `FilledButton` with `Key('confirmation-confirm')` and `confirmLabel`; it pops `true`. The normal style uses `styleFrom` with the primary fill and on-primary text. The danger style uses `styleFrom` with the error fill and on-error text.

The test file pumps a `MaterialApp` with `AppTheme.light` unless a case says dark, at a logical viewport of 400×800 for phone and 601×800 for desktop. Open the dialog through `showConfirmationDialog`.

Assert:

- On phone and desktop, the title, message, `Cancel`, and confirm label are shown, the title font size is 20 on phone and 22 on desktop, and the message font size is 14.
- The keyed dialog is 352 wide on a 400-wide phone viewport and 440 wide on a desktop viewport.
- With no warning, `confirmation-warning` is absent. With a warning, that key shows the warning text. In the light theme the banner background is `#FFDDB3` and the foreground is `#8A5000`. In the dark theme the background is `#6A3C00` and the foreground is `#FFB86B`.
- Tapping Cancel removes the dialog and completes `false`. Tapping the scrim does the same.
- Tapping a normal confirm removes the dialog and completes `true`, and that button's background resolves to `ColorScheme.primary` and its foreground to `ColorScheme.onPrimary`.
- Tapping a danger confirm removes the dialog and completes `true`, and that button's background resolves to `ColorScheme.error` and its foreground to `ColorScheme.onError`.

**Spot-check**

`flutter test test/ui/confirmation_dialog_test.dart`

- Every test in that file passes.

**Done when:** The acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
