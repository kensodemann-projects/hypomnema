# PLAN-3 — Add email-and-password sign-in and forgot-password

Issue: [#3](https://github.com/kensodemann-projects/hypomnema/issues/3) (OPEN).

Related to [#1](https://github.com/kensodemann-projects/hypomnema/issues/1).

`lib/main.dart` initializes Firebase for Android, macOS, and web, and in debug mode points `FirebaseAuth.instance` at the Auth emulator on port 9099. `MainApp` then shows `Shell`: a phone scaffold at width 600 and below, and a desktop scaffold above 600. There is no auth service and no login screen. Sign-in, forgot-password, and account creation are not implemented. `test/main_test.dart` covers `MainApp` brightness and those `Shell` widths.

**Decisions**

- `LoginScreen` takes an `AuthService` and is not assigned to `MainApp.home`. Issue #4 mounts the screen and adds sign-out.
- Forgot-password stays on `LoginScreen` and replaces the sign-in form. **Back to sign in** restores that form. The email already typed is kept.
- A `FirebaseAuthException` is shown as `message` when that is non-null, and as `code` when `message` is null. Any other exception propagates.
- After `sendPasswordResetEmail` succeeds, the screen shows `Check your email for a password reset link.`
- Switching between sign-in and forgot-password clears the Firebase error and the reset confirmation. **Forgot password** can be pressed only while the email is valid, so that switch starts with no email validation error. Hiding the password field clears its validation state, and the restored password field starts valid until the user leaves it. **Sign in** stays disabled on return until the password trim is non-empty.
- **Sign in** has `onPressed` null until the trimmed email matches the pattern and the password trim is non-empty, and while a request is in progress. **Forgot password** has `onPressed` null until the trimmed email matches the pattern, and while a request is in progress. Enabled state follows the current text, including after a keystroke clears the visible error. **Send reset email** does nothing while a request is in progress.
- The width split matches `Shell`: above 600 the form sits in a centered card whose max width is 400; at 600 and below it is a full-width column and no card.
- The phone column is wrapped in `Padding` of `EdgeInsets.all(16)`. The desktop card's child is `Padding` of `EdgeInsets.all(24)`.
- The column leaves 16 pixels between fields, 16 pixels before the Firebase error and before the reset confirmation, 24 pixels before the primary button, and 8 pixels between that button and the text button under it. The same gaps wrap whichever form is visible.
- Email and password start valid. A field is checked when it loses focus, and again when **Sign in** or **Send reset email** is pressed. The first keystroke in a field clears that field's validation error.
- Email is required, then must be a valid address. The check and the value sent to `AuthService` both use the trimmed email. An empty trim shows `Email is required.` A non-empty trim that fails the pattern shows `Enter a valid email address.` The pattern is `^[^@\s]+@[^@\s]+\.[^@\s]+$`.
- Password is required. A trim that is empty shows `Password is required.` A password that still has characters after trim is sent unchanged, including surrounding spaces.
- Each validation message is `InputDecoration.errorText`. `errorStyle`, `errorBorder`, and `focusedErrorBorder` stay unset, so `material_ui` paints the message, the label, and the border with `ColorScheme.error`.
- `sendPasswordResetEmail` is called with the trimmed email only, and only when that email passes validation. **Sign in** calls `signInWithEmailAndPassword` only when its button is enabled.
- A preview harness sits at the bottom of `lib/ui/auth/login_screen.dart` so the screen can be viewed without changing `MainApp.home`. It wraps `LoginScreen` in `material_ui`'s `MaterialApp` and a no-op `AuthService`, with a phone preview at 400 by 800 and a desktop preview at 1200 by 800.

**Out of scope**

- Installing the login screen as the signed-out home, hiding `Shell` until sign-in, and sign-out. Those belong to [#4](https://github.com/kensodemann-projects/hypomnema/issues/4).
- Creating accounts, including `createUserWithEmailAndPassword`, and any hardcoded user.
- Changing the emulator host and ports already set in `main`.
- Notes, Firestore documents, and platform placeholders beyond this screen.
- `.widget_preview/` is already ignored.

**Contract**

- Email field label: `Email`. Password field label: `Password`.
- Sign-in action: `Sign in`. Forgot-password action: `Forgot password`.
- Reset action: `Send reset email`. Return action: `Back to sign in`.
- Reset confirmation: `Check your email for a password reset link.`
- Email required: `Email is required.` Email format: `Enter a valid email address.` Password required: `Password is required.`
- Valid emails include `person@example.com` and ` person@example.com `. Invalid emails include an empty field, `person`, `person@example`, and `@example.com`.
- **Sign in** is disabled until the email is valid and the password trim is non-empty. **Forgot password** is disabled until the email is valid. Both are also disabled while a request is in progress.
- Phone layout at width 600 and below, inset by 16 pixels on every side. Desktop card at width greater than 600, max width 400, with 24 pixels of padding inside the card.
- Vertical gaps: 16 between fields, 16 before `login-error` and before `login-reset-confirmation`, 24 before **Sign in** or **Send reset email**, 8 between that button and **Forgot password** or **Back to sign in**.
- Widget keys: `login-email`, `login-password`, `login-sign-in`, `login-forgot-password`, `login-send-reset`, `login-back-to-sign-in`, `login-form-card`, `login-error`, `login-reset-confirmation`.

**File order**

| Order | Step       | Status | Files                                                                                   |
| ----- | ---------- | ------ | --------------------------------------------------------------------------------------- |
| 1     | [STEP-001] |        | `lib/data/services/auth_service.dart`, then `test/data/services/auth_service_test.dart` |
| 2     | [STEP-002] |        | `lib/ui/auth/login_screen.dart`, then `test/ui/auth/login_screen_test.dart`             |
| 3     | [STEP-003] |        | `lib/ui/auth/login_screen.dart`, then `test/ui/auth/login_screen_test.dart`             |

**Commit gate** — the human commits. A spot-check does not replace the gate. The repository has no separate build command. `make check` runs these three, and all three must succeed with no warning or error before that commit:

```bash
make format-check
make analyze
make test
```

## [STEP-001] Forward email sign-in and password reset to Firebase Auth

**Status:**

**Acceptance criteria:** `FirebaseAuthService` forwards each email and password to `FirebaseAuth.signInWithEmailAndPassword`, forwards each reset email to `FirebaseAuth.sendPasswordResetEmail` with no action-code settings, and lets `FirebaseAuthException` propagate. It has no account-creation method.

**Files**

1. `lib/data/services/auth_service.dart` — add `AuthService` and `FirebaseAuthService`.
2. `test/data/services/auth_service_test.dart` — cover forwarding and exception propagation for more than one account.

**Change**

Add `abstract class AuthService` with `signInWithEmailAndPassword({required String email, required String password})` and `sendPasswordResetEmail({required String email})`. `FirebaseAuthService` implements it with constructor `FirebaseAuthService({this.firebaseAuth})`, a public `final FirebaseAuth? firebaseAuth`, and `FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance`. Each method awaits the matching `FirebaseAuth` call. `sendPasswordResetEmail` passes only the email. Do not add `createUserWithEmailAndPassword` or a stored user.

The test fake implements `FirebaseAuth`, records both calls, can throw a `FirebaseAuthException`, and uses `noSuchMethod` for unused members. Assert two different sign-in calls are forwarded in order, one reset email is forwarded with `actionCodeSettings` null, and a thrown `FirebaseAuthException` from either method propagates with its `code`.

**Spot-check**

```bash
flutter test test/data/services/auth_service_test.dart
```

- Two sign-in accounts and one reset email are recorded, and both thrown `FirebaseAuthException`s propagate.

**Done when:** the acceptance criteria hold, and build, test, and lint succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.

## [STEP-002] Sign in from a phone column and a desktop card

**Status:**

**Acceptance criteria:** The login screen collects an email and password and checks each field when it loses focus. **Sign in** stays disabled until the trimmed email matches the pattern and the password trim is non-empty, then calls `AuthService.signInWithEmailAndPassword`. A failing field shows its message in the error color, with the label and border in the error color. Typing in a field clears that field's message and updates whether **Sign in** is enabled. A `FirebaseAuthException` shows its message or code. Width 600 and below is a full-width column inset by 16 pixels. Width above 600 is a centered card of max width 400 with 24 pixels inside the card. Fields are 16 pixels apart, and 24 pixels separate the fields from **Sign in**. A successful sign-in does not navigate and does not show the reset confirmation. Phone and desktop previews sit at the bottom of the login screen file.

**Files**

1. `lib/ui/auth/login_screen.dart` — add the sign-in form, both layouts, and the preview harness.
2. `test/ui/auth/login_screen_test.dart` — cover layout, field validation, forwarded credentials, and the failure text.

**Change**

Add `LoginScreen`, a `StatefulWidget` that requires `AuthService`. Import UI widgets from `package:material_ui/material_ui.dart`. Use a `Scaffold` whose body is a `LayoutBuilder`. Above width 600, center a `Card` keyed `login-form-card`, constrain it to a max width of 400, and pad its child with `EdgeInsets.all(24)`. At width 600 and below, pad the column with `EdgeInsets.all(16)` and omit the card. The form is a `Column` with `mainAxisSize: MainAxisSize.min` and `crossAxisAlignment: CrossAxisAlignment.stretch`. It has an `Email` `TextField` keyed `login-email`, a `SizedBox(height: 16)`, a `Password` `TextField` keyed `login-password` with `obscureText`, a `SizedBox(height: 24)`, and a `Sign in` `FilledButton` keyed `login-sign-in`. When `login-error` is shown, put a `SizedBox(height: 16)` before it and keep the `SizedBox(height: 24)` immediately before **Sign in**.

Give each field a `FocusNode`. Both fields start with `errorText` null. When a field's focus node reports that it lost focus, validate that field. On the email field's `onChanged`, clear the email error. On the password field's `onChanged`, clear the password error. Put the message in `InputDecoration.errorText` and leave `errorStyle`, `errorBorder`, and `focusedErrorBorder` null.

Email validation trims the text. An empty trim sets `Email is required.` Otherwise match `RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')` against the trim; a failure sets `Enter a valid email address.` Password validation trims only to decide required: an empty trim sets `Password is required.`

**Sign in** uses `onPressed: null` until the trimmed email matches the pattern and the password trim is non-empty. Recompute that on each field's `onChanged`, including when the keystroke clears a visible error. When enabled, the button calls `signInWithEmailAndPassword` with the trimmed email and the password text as typed, then sets `onPressed` null while that future is running. On success, leave the form in place and show neither `login-error` nor `login-reset-confirmation`. On `FirebaseAuthException`, show `message` when non-null and `code` otherwise in a `Text` keyed `login-error`. Let any other exception propagate. Do not add the forgot-password control in this step, and do not change `lib/main.dart`.

At the bottom of the same file, import `package:flutter/widget_previews.dart` and add `_PreviewAuthService`, `LoginScreenPreviewHarness`, and two preview functions. `_PreviewAuthService` implements `AuthService` and completes both methods without calling Firebase. `LoginScreenPreviewHarness` returns `MaterialApp` with `theme: ThemeData.light()`, `darkTheme: ThemeData.dark()`, `themeMode: ThemeMode.system`, and `home: LoginScreen(authService: _PreviewAuthService())`. The previews are `@Preview(name: 'Phone', group: 'Login screen', size: Size(400, 800))` and `@Preview(name: 'Desktop', group: 'Login screen', size: Size(1200, 800))`, each returning `const LoginScreenPreviewHarness()`.

Widget tests pump `LoginScreen` inside `MaterialApp` with a fake `AuthService`. Assert the phone column at widths 400 and 600, the card at widths 601 and 1200, and two different valid credential pairs forwarded as a trimmed email and an untrimmed password. Assert the phone padding is `EdgeInsets.all(16)` and the card's inner padding is `EdgeInsets.all(24)`. Assert 16 pixels between the email and password fields and 24 pixels between the password field and **Sign in**. Assert `message` shown when present, `code` shown when `message` is null, and no confirmation text after a successful sign-in.

Assert a field shows no `errorText` before it loses focus. After the email field loses focus, an empty value shows `Email is required.` and `person` shows `Enter a valid email address.` After the password field loses focus, an empty value shows `Password is required.` Typing one character clears that field's `errorText` while the text is still invalid. **Sign in** has `onPressed` null for an empty form, a valid email with an empty password, and an invalid email with a non-empty password. It has a non-null `onPressed` for `person@example.com` and `secret`, and a tap then calls `AuthService`. For a visible error, the message text color, the field label color, and the field border color are `Theme.colorScheme.error`.

**Spot-check**

```bash
flutter test test/ui/auth/login_screen_test.dart
```

- Phone widths have no card and 16 pixels of padding, desktop widths have the card and 24 pixels inside it, the field and button gaps match, **Sign in** stays disabled until both fields are valid, valid credentials are forwarded, invalid fields use the error color, and failure text matches the exception.

**Done when:** the acceptance criteria hold, and build, test, and lint succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.

## [STEP-003] Replace the sign-in form with forgot-password

**Status:**

**Acceptance criteria:** **Forgot password** stays disabled until the trimmed email matches the pattern. Pressing it replaces the sign-in form with that email, **Send reset email**, and **Back to sign in**. The email field keeps the same required and format checks. **Send reset email** sends the trimmed email only when it passes. A successful send shows `Check your email for a password reset link.` A `FirebaseAuthException` shows its message or code and does not show that confirmation. **Back to sign in** restores the password field, valid until the user leaves it, and **Sign in** enabled only when the password trim is non-empty.

**Files**

1. `lib/ui/auth/login_screen.dart` — add the forgot-password mode on the existing form.
2. `test/ui/auth/login_screen_test.dart` — cover the mode switch, reset send, confirmation, failure, and return.

**Change**

Add a `Forgot password` `TextButton` keyed `login-forgot-password` on the sign-in form, with a `SizedBox(height: 8)` between **Sign in** and that button. Its `onPressed` is null until the trimmed email matches the pattern, and while a request is in progress. Activating it hides the password field and **Sign in**, keeps the email field and its text, and shows **Send reset email** keyed `login-send-reset` and **Back to sign in** keyed `login-back-to-sign-in`. On that form, keep 16 pixels before a visible Firebase error or reset confirmation, 24 pixels before **Send reset email**, and 8 pixels between **Send reset email** and **Back to sign in**. Clear the Firebase error, the reset confirmation, and the password validation error when the mode changes. The phone column and desktop card still wrap whichever form is visible. Leave the preview harness at the bottom of the file.

**Send reset email** runs the email check first. If it fails, show that field error and do not call `AuthService`. When it passes, call `sendPasswordResetEmail` with the trimmed email and set `onPressed` to null while the future is running. On success, show `Check your email for a password reset link.` keyed `login-reset-confirmation`. On `FirebaseAuthException`, show `message` or `code` in `login-error` and do not show the confirmation. **Back to sign in** restores the sign-in form, keeps the email text and email validation state, and shows the password field with no validation error until it loses focus.

Extend the widget tests: assert **Forgot password** has `onPressed` null for an empty email and for `person`, and a non-null `onPressed` for `person@example.com`. From the sign-in form, enter that valid email, open forgot-password, and assert the password field and **Sign in** are gone while the email remains. Clear the email and assert **Send reset email** does not call `sendPasswordResetEmail` and shows `Email is required.` Assert a send of `person@example.com` forwards that trimmed email and shows the confirmation. Assert a thrown `FirebaseAuthException` shows its message and hides the confirmation. Assert **Back to sign in** restores a password field with no validation error, and **Sign in** has `onPressed` null until the password trim is non-empty. Assert the reset form is outside `login-form-card` at width 400 and inside it at width 601. Assert 24 pixels before **Send reset email** and 8 pixels between that button and **Back to sign in**.

**Spot-check**

```bash
flutter test test/ui/auth/login_screen_test.dart
```

- **Forgot password** stays disabled until the email is valid, the reset form replaces sign-in, an invalid email blocks the send, a valid email is forwarded, the confirmation or the exception text is shown, and **Back to sign in** restores the sign-in form on both layouts.

**Done when:** the acceptance criteria hold, and build, test, and lint succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
