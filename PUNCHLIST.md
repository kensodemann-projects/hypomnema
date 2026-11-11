# Punch list — `3-add-email-and-password-sign-in-and-forgot-password`

Based on a code-quality review comparing this branch with `3-argon`, checked against commit `756fdc2` ("WIP - code cleanup").

## Done in `756fdc2`

- [x] Show the failure message (`login-error`) in `colorScheme.error`.
- [x] Stop showing Firebase's text or raw code on sign-in failure.

## Loose ends from `756fdc2`

- [x] **Forgot-password errors still show raw Firebase text.** `_sendResetEmail` still sets `error.message ?? error.code` (line 162 of `lib/ui/auth/login_screen.dart`). Change it to match sign-in or map it to a friendly message, and update the test "when the reset email fails, then the message is shown…".
- [x] **Capitalisation doesn't match the other messages.** Change "Authentication Failed." to sentence case ("Authentication failed.") to match "Email is required." and the rest, and update the test.
- [x] **One test name is now inaccurate.** Rename "Given a FirebaseAuthException, when sign-in fails, then the message or code is shown" (line 358 of the test file). That test also repeats the same assertion twice now; collapse it to one case, or keep the second only to show that a missing message gives the same result.
- [x] **`PLAN.md` still describes the old behaviour.** It says the message or code is shown, at line 13 and in both step acceptance criteria (lines 97 and 136), and the Contract section doesn't list the new text.

## Service layer

- [x] Declare `AuthService` as an `abstract interface class`.
- [ ] Make the injected Firebase field private: `FirebaseAuthService({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth;`.
- [ ] Consider translating `FirebaseAuthException` into an app-level error inside the service. The screen and its tests would then no longer import `firebase_auth`, and the error-message mapping would live in one place. Any other exception type still goes unhandled.
- [ ] In `test/data/services/auth_service_test.dart`, use `await expectLater(...)` instead of `expect(() => ..., throwsA(...))` for the async exception tests.

## Login screen

- [ ] **Password check:** stop trimming the password when checking whether it's empty (`text.trim().isEmpty`, line 20), so whitespace-only passwords are handled the same way as other passwords.
- [ ] **Autofill:** add `autofillHints` (email and password) and wrap the fields in an `AutofillGroup`.
- [ ] **Enter key:** set `textInputAction` and `onSubmitted` so that Enter moves from email to password and then submits. This matters most on macOS.
- [ ] **Scroll view:** wrap the form in a `SingleChildScrollView` so the phone layout doesn't overflow with the keyboard open or on short screens.
- [ ] **Button rules:** make "Send reset email" follow the same rule as "Forgot password" (disabled until the email is valid), or deliberately keep the validate-on-press approach and record that choice in the plan.
- [ ] **Loading indicator:** optionally show progress while a request is running.
- [ ] **Previews:** replace the public `LoginScreenPreviewHarness` class with one private preview function carrying both `@Preview` annotations.
- [ ] **Widget helpers:** optionally turn `_emailField()`, `_feedback()` and `_form()` into small private widget classes.

## Widget tests (`test/ui/auth/login_screen_test.dart`)

- [ ] Remove the pixel-scanning border-colour check: the `pixelColor` helper (line 87) and the loop that uses it (around line 225). Checking the label and error text colours is enough.
- [ ] Remove the assertions that `errorStyle`, `errorBorder` and `focusedErrorBorder` are null (around line 214).
- [ ] Remove the exact pixel-gap checks (16, 24 and 8) and the exact `EdgeInsets` padding checks. Keep the checks for which layout is used: card versus no card, and the 400 maximum width.
- [ ] Remove the dead assertions that "Phone" and "Desktop" are absent (line 127).
- [ ] Remove the `key: ValueKey(size)` workaround in `pumpLoginScreen` (line 62), for example by giving each width its own test. Removing the gap and padding checks may also remove the need for it.
- [ ] Add tests for any new behaviour: autofill hints, Enter to submit, and the forgot-password error message.

## Plan, Makefile and history

- [x] Trim `PLAN.md`'s contract: drop the pixel gaps, padding values and null-decoration requirements that drove the brittle tests, and add any new decisions (error text, Enter key, autofill).
- [x] Add `preview` to the Makefile's `.PHONY` line.
- [x] Squash the WIP commits when merging.

