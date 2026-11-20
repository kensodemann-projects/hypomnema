# PLAN-20 — Redesign the sign-in screen

Issue: [#20](https://github.com/kensodemann-projects/hypomnema/issues/20) (OPEN).

Related to [#17](https://github.com/kensodemann-projects/hypomnema/issues/17).

`LoginScreen` in `lib/features/auth/ui/login_screen.dart` shows Email, Password, Sign in, and Forgot password, then replaces that form with a reset form when Forgot password is pressed. Field helpers already show `Email is required.`, `Enter a valid email address.`, and `Password is required.`, and Sign in is enabled only for a valid email and password. Sign-in failure, reset success, and reset failure are inline text, not snackbars. At a width of 600 and below the form is a padded column; above that it sits in a card 400 wide. The screen has no logo, Hypomnema name, or quote. `FirebaseAuthService.sendPasswordResetEmail` in `lib/features/auth/data/auth_service.dart` already forwards the address to Firebase and throws `AuthException` on `FirebaseAuthException`. The issue names `lib/ui/auth/` and `lib/data/services/`; those files are not in the tree.

**Decisions**

- The success snackbar keeps the current sentence, `Check your email for a password reset link.`
- The reset-failure snackbar says `A reset link could not be sent. Try again.`
- The success snackbar uses the mock-up info banner colors for the current brightness: light background `#D4E3FF` and foreground `#0C5DA8`; dark background `#00468A` and foreground `#A5C8FF`. An error snackbar uses `ColorScheme.errorContainer` and `ColorScheme.error`.
- Those info colors stay on the sign-in screen. This task does not add them to `AppColors`.
- The logo is a widget painted to match `docs/ui-mockups/desktop/logo.svg`. No new package or asset.
- Desktop layout remains `constraints.maxWidth > 600`.
- The screen omits `Use the account you were given.` and `Accounts are created for you. There is no sign-up.` Those lines stay in the mock-ups only.

**Out of scope**

- Creating accounts, and changing a password inside the app.
- `AuthService` and `FirebaseAuthService`.
- The mock-up banner that explains Forgot password before it is pressed, and the inline helper `Incorrect email or password.`
- The signed-in shell, the auth gate, and `AppTheme`.

**Contract**

- Desktop heading `Sign in`.
- Desktop quote `A note kept so it can be found again: a reminder, a memorandum, a short record of something worth remembering.`
- Phone quote `A note kept so it can be found again.`
- Name `Hypomnema`. Buttons stay `Sign in` and `Forgot password`.
- Light brand gradient `#4A55C8` to `#2E3694`. Dark brand gradient `#2B3290` to `#151A55`. Brand text is white.
- Logo is 72 by 72. The desktop form side is 520 wide, and the form column is at most 360 wide.

**File order**

| Order | Step       | Status | Files                                                                                                      |
| ----- | ---------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| 1     | [STEP-001] |        | `lib/features/auth/ui/hypomnema_logo.dart`, then `lib/features/auth/ui/login_screen.dart`, then `test/features/auth/ui/login_screen_test.dart` |
| 2     | [STEP-002] |        | `lib/features/auth/ui/login_screen.dart`, then `test/features/auth/ui/login_screen_test.dart`              |

**Commit gate** — the human commits. A spot-check does not replace the gate.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit. `make check` already runs the tests.

## [STEP-001] Match the phone and desktop sign-in layouts

**Status:**

**Acceptance criteria:** A signed-out person sees the redesigned sign-in screen on phone and on desktop, in light and in dark, with the logo, the Hypomnema name, and that layout's quote. Desktop places the brand panel beside the form. Phone stacks the brand above the form.

**Files**

1. `lib/features/auth/ui/hypomnema_logo.dart` — paint the mark from `docs/ui-mockups/desktop/logo.svg` at 72 by 72.
2. `lib/features/auth/ui/login_screen.dart` — replace the card and padded column with the two layouts. Keep the current form, including the reset form.
3. `test/features/auth/ui/login_screen_test.dart` — replace the card assertions with the layout contract. Pump `AppTheme.light` and `AppTheme.dark`.

**Change**

Add `HypomnemaLogo`, keyed `login-logo`, and give it a 72 by 72 box. Reproduce the SVG: a rounded square from `#6E78F0` to `#3A44B8`, a white document with a folded corner, three rules, and the bookmark.

Keep `maxWidth > 600` as desktop. On desktop, use a row. The brand panel, keyed `login-brand`, fills the remaining width, pads 64, and uses a 150° gradient with the contract stops for the active brightness. White text shows the logo, `Hypomnema` at 40, and the desktop quote in italic at 18 with opacity 0.85. The form side is 520 wide and centers a column at most 360 wide. That column shows `Sign in` at 26, then the existing form. `Use the account you were given.` is absent.

On phone, use a `SafeArea`, padding of 24 by 28, and a scrollable centered column. Stack the logo, `Hypomnema` at 28, and the phone quote in italic at 15 in `onSurfaceVariant`. Then show the existing form. `Accounts are created for you. There is no sign-up.` is absent. The brand panel, desktop heading, and desktop quote are absent.

Leave Email, Password, Sign in, Forgot password, validation, and the reset form behavior as they are. Keep their keys.

In the test, default the pumped theme to `AppTheme.light` and pass `AppTheme.dark` for the dark case. Assert the contract copy, which quote each layout shows, the logo size, the form-side width, the form-column max width, and the brand gradient stops in both themes. Widths 400 and 600 stay phone. Widths 601 and 1200 stay desktop. Leave the reset-form and validation tests in place.

**Spot-check**

```bash
flutter test test/features/auth/ui/login_screen_test.dart
```

- Phone and desktop assertions match the contract in light and in dark, and the existing form tests pass.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.

## [STEP-002] Keep reset on the sign-in screen and show snackbars

**Status:**

**Acceptance criteria:** Email, Password, Sign in, and Forgot password stay on one screen. Forgot password does not open another form. Before it is pressed, the screen shows no reset message. An empty email shows `Email is required.` and no snackbar. A malformed email shows `Enter a valid email address.` and no snackbar. A valid email calls `sendPasswordResetEmail`. Success shows the info snackbar. Failure shows the error snackbar. A failed sign-in shows an error snackbar that says `Authentication failed.` An empty password shows `Password is required.` Sign in stays available only when the email and password are valid.

**Files**

1. `lib/features/auth/ui/login_screen.dart` — remove the reset form, validate email when Forgot password is pressed, and show transient snackbars for sign-in failure, reset success, and reset failure.
2. `test/features/auth/ui/login_screen_test.dart` — replace the reset-form tests with the single-screen and snackbar assertions.

**Change**

Remove the reset-form branch, `Send reset email`, `Back to sign in`, and the inline error and confirmation text. The email field keeps `TextInputAction.next` and still moves focus to the password field. The password field still submits sign-in on Enter when the pair is valid.

Forgot password stays pressable while no sign-in or reset call is in progress, including when the email is empty or malformed. Pressing it with an empty or malformed email sets that field's existing helper and does not call `sendPasswordResetEmail` or show a snackbar. Pressing it with a valid email calls `sendPasswordResetEmail` with the trimmed address. Success shows a `SnackBar` with the success sentence and the info colors for the current brightness. `AuthException` shows a `SnackBar` with the failure sentence, background `ColorScheme.errorContainer`, and foreground `ColorScheme.error`. Leave the default `SnackBar` duration in place so the message is transient. The password field and Sign in remain on screen.

Sign-in failure shows a `SnackBar` with `Authentication failed.` in those same error colors, instead of inline text. Sign in stays disabled until the email and password are valid, and both Sign in and Forgot password stay disabled until the in-flight call finishes. Blur validation is unchanged. A successful sign-in still shows neither an error nor a reset message.

Update the tests to match. Assert that the first frame has no `SnackBar` and no reset sentence. Assert the empty and malformed Forgot password cases show the helper, find no `SnackBar`, and record no reset call. Assert a spaced valid email is trimmed, the form keys remain, and the success snackbar uses the light info colors. Repeat the success case under `AppTheme.dark` for the dark info colors. Assert reset failure and sign-in failure show their sentences in the theme error colors, and that after the default snackbar duration those messages are gone. Remove expectations for `login-send-reset`, `login-back-to-sign-in`, `login-error`, and `login-reset-confirmation`.

**Spot-check**

```bash
flutter test test/features/auth/ui/login_screen_test.dart
```

- The single-screen, validation, and snackbar assertions pass, including light and dark info colors.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
