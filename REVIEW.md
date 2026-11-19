# Review: Add the shared confirmation dialog

PR: https://github.com/kensodemann-projects/hypomnema/pull/25

## Summary

This review covers the resulting diff of [PR #25](https://github.com/kensodemann-projects/hypomnema/pull/25): the shared confirmation dialog, its widget tests, the login-screen preview removal, and `PLAN.md`. Recommendation: request changes. The dialog follows the phone and desktop contract, and the tests lock copy, width, warning colors, and both confirm styles. CLN-001 is complete: `799b8b4` closes the dialog only once via `_close`. CLN-002 is complete: `1652744` sets `scrollable: true` on `AlertDialog`. `PLAN.md` still says this change does not touch `LoginScreen`. The removed login previews and the nearest-navigator choice are open questions for how later actions will call this dialog.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     1 |
| 📚 Documentation gaps                      |     1 |
| ✅ Positive feedback                       |     1 |
| ✅ Resolved                                |     2 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     2 |
| **Total**                                  |     5 |

## Findings

### ✅ Resolved

[CLN-001]

**Status:** Complete — verified in `799b8b4`. `ConfirmationDialog` is a `StatefulWidget` with `_closed` and `_close`; Cancel and confirm call `_close` instead of `Navigator.pop` directly.

**Issue:** Cancel and confirm called `Navigator.pop` with no guard. After the first pop, Flutter moves that route to the `popping` lifecycle. The route stays visible for the exit animation, and it is no longer a present route. A second tap during that animation could call `Navigator.pop` again and pop the route underneath while `showConfirmationDialog` had already completed.

**Suggestion:** Close the dialog once with a `State` flag and wire Cancel and confirm through `_close`.

**Why:** This dialog is the shared gate for sign-out, delete, and archive. A second tap should leave the underlying page in place. The future should still complete once, with the first choice.

[CLN-002]

**Status:** Complete — verified in `1652744`. `AlertDialog` sets `scrollable: true` so title and content scroll while actions stay fixed, matching the review suggestion with no further CLN-002 work.

**Issue:** `AlertDialog` used the default `scrollable: false`, so a long message, large text scale, or short window could overflow the column.

**Suggestion:** Set `scrollable: true` on `AlertDialog`.

**Why:** Callers pass arbitrary title, message, and warning strings. Scrolling the body keeps Cancel and the confirm action reachable, consistent with the mock-ups.

### 🧹 Code cleanup and maintainability (open)

[CLN-003]

**Issue:** The preview awaits the dialog and then calls `setState` with no `mounted` check. Reloading the preview disposes `_ConfirmationDialogPreviewState` while the route is still open, and that `setState` throws.

**Suggestion:**

```dart
final confirmed = await showConfirmationDialog(
  context: context,
  title: title,
  message: message,
  confirmLabel: confirmLabel,
  style: style,
  warning: warning,
);
if (!mounted) return;
setState(() {
  _result = confirmed ? 'Confirmed.' : 'Canceled.';
});
```

**Why:** The preview is the manual check in the pull request test plan. A reload during an open dialog should end quietly.

### 📚 Documentation gaps

[DOC-001]

**Issue:** `PLAN.md` says this step does not change `LoginScreen`. The diff deletes `_PreviewAuthService` and the phone and desktop login previews from `lib/ui/auth/login_screen.dart`. The file list for STEP-001 also omits that file.

**Suggestion:** After the preview decision in QST-001, make the opening paragraph and the STEP-001 file list describe the same tree as the diff. If the previews stay deleted, name `lib/ui/auth/login_screen.dart` and say the login previews moved off this screen. If they are restored, the current sentence holds.

**Why:** This repository commits the root plan with the branch. A later reader will treat "does not change `LoginScreen`" as the scope that landed.

### ✅ Positive feedback

[POS-001]

**Issue:** The shared dialog is a small, test-backed API that matches the task contract.

**Suggestion:** Keep this shape. `showConfirmationDialog` returns `Future<bool>`, maps a null pop to `false`, and takes the confirm label and `ConfirmationStyle` as arguments. Phone width is the viewport minus 48 (352 on a 400-wide view) with a 20px title and a 14px gap. Desktop width is 440 with a 22px title and a 16px gap. The breakpoint is the same `maxWidth > 600` check `Shell` and `LoginScreen` use. A null or empty warning omits the banner. Light and dark warning colors are the mock-up `--warning` and `--warning-container` tokens, and the widget tests assert both. The nested-navigator test locks `useRootNavigator: false`, which is what lets the preview host show the dialog. UI widgets come from `package:material_ui/material_ui.dart`.

**Why:** Later sign-out, delete, and archive calls can sit on this result and these two layouts without a second dialog implementation.

### 💭 Questions for discussion

[QST-001]

**Issue:** The diff removes the only widget previews for the login screen: `Login Screen - Phone`, `Login Screen - Desktop`, and `_PreviewAuthService`. The pull request describes those previews as unused. `make preview` discovers `@Preview` widgets, so those two were the preview entry for sign-in.

**Suggestion:** Decide whether `make preview` should still open the login screen. Restoring the two `@Preview` annotations and `_PreviewAuthService` keeps that entry beside the new confirmation-dialog previews. Leaving them deleted means login is checked through `flutter test` and `flutter run` until another preview is added.

**Why:** The confirmation previews can exist in `confirmation_dialog.dart` while the login previews stay in `login_screen.dart`. The two files do not compete for the preview catalog.

[QST-002]

**Issue:** `showConfirmationDialog` passes `useRootNavigator: false`, so the dialog is pushed on the nearest navigator. The new test builds a `MaterialApp` under an outer `Navigator` and expects the dialog on the inner one. The running app has a single navigator today, so nearest and root are the same route stack. A later screen that calls this from a nested navigator will cover only that navigator.

**Suggestion:** Confirm that nearest-navigator scope is what sign-out, delete, and archive should use. If a confirmation should cover the shell, including the rail or the bottom bar, the production call wants the root navigator, and the preview host can pass a narrower setting.

**Why:** The flag is part of the public function, and every later caller inherits it. The preview host and a full-window confirmation want different navigators.
