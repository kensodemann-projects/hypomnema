## Summary

Reviewed [PR #12](https://github.com/kensodemann-projects/hypomnema/pull/12) (`Makefile`, `lib/data/services/auth_service.dart`, `lib/ui/auth/login_screen.dart`, and their corresponding unit and widget tests). Overall recommendation: **Approve** with minor suggestions. The implementation cleanly satisfies the email-and-password sign-in and password-reset requirements from [#3](https://github.com/kensodemann-projects/hypomnema/issues/3), uses fixed user-facing error messages that avoid leaking raw Firebase errors or account enumeration details, adapts between phone and desktop layouts, and is backed by thorough Given/When/Then test coverage. The findings below focus on preventing form-mode switching while a password-reset request is in flight, protecting the phone layout from status-bar overlap with `SafeArea`, and keeping the `AuthService` abstraction decoupled from `package:firebase_auth`.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     3 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     2 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     0 |
| **Total**                                  |     5 |

## Findings

[CLN-001]
**Issue:** On the password-reset form in `lib/ui/auth/login_screen.dart` (lines 228–232), the `Back to sign in` button (`Key('login-back-to-sign-in')`) remains enabled while `_submitting` is `true`. By contrast, `Forgot password` on the sign-in form is disabled while a request is in flight (`_canResetPassword` checks `!_submitting`). If a user taps `Send reset email` and then taps `Back to sign in` before the async call finishes, `_sendResetEmail()` will complete while the sign-in form is visible and render the reset confirmation or reset error message onto the sign-in form.  
**Suggestion:** Disable `Back to sign in` while `_submitting` is `true`, matching the in-flight behavior of `Forgot password`:
```dart
TextButton(
  key: const Key('login-back-to-sign-in'),
  onPressed: _submitting ? null : _showSignInForm,
  child: const Text('Back to sign in'),
),
```
**Why:** Prevents state from an in-flight password-reset request from leaking into the sign-in view and keeps button enablement consistent across both form modes.

[CLN-002]
**Issue:** In `lib/ui/auth/login_screen.dart` (lines 290–292), the phone branch returns a `Scaffold` with no `AppBar` and no `SafeArea` around the `Padding`. On mobile devices (such as Android with edge-to-edge display or cutouts), the top `Email` field can render underneath the system status bar.  
**Suggestion:** Wrap the phone body in a `SafeArea`:
```dart
return Scaffold(
  body: SafeArea(
    child: Padding(padding: const EdgeInsets.all(16), child: form),
  ),
);
```
**Why:** Ensures the form controls remain clear of system status bars, notches, and gesture insets on phone viewports.

[CLN-003]
**Issue:** `LoginScreen` depends on the `AuthService` interface (`lib/data/services/auth_service.dart`), yet `lib/ui/auth/login_screen.dart` still imports `package:firebase_auth/firebase_auth.dart` directly to catch `FirebaseAuthException` in `_signIn()` and `_sendResetEmail()`.  
**Suggestion:** Either document `FirebaseAuthException` on the `AuthService` contract or translate `FirebaseAuthException` into a domain-level exception (e.g., `AuthException`) inside `FirebaseAuthService` so `LoginScreen` and its widget tests do not need to import `package:firebase_auth/firebase_auth.dart`.
```dart
class AuthException implements Exception {
  const AuthException();
}
```
**Why:** Keeps Firebase-specific types encapsulated in the data layer behind `AuthService` and simplifies UI tests.

[POS-001]
**Issue:** Authentication and password-reset error handling in `lib/ui/auth/login_screen.dart` (lines 104–108, 166–170).  
**Suggestion:** Catching authentication failures and presenting fixed messages (`'Authentication failed.'` and `'Failed to send password reset email.'`) rather than surfacing raw Firebase error codes or messages works well here.  
**Why:** Avoids leaking sensitive implementation details or enabling account enumeration through differentiated error responses.  
**Documentation:** https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html

[POS-002]
**Issue:** Test suite structure and coverage in `test/data/services/auth_service_test.dart` and `test/ui/auth/login_screen_test.dart`.  
**Suggestion:** The tests thoroughly exercise responsive layout breakpoints (`600` vs `601`), focus/blur validation, keyboard action progression (`TextInputAction.next` and `TextInputAction.done`), input trimming rules, and in-flight request disabling using clear Given/When/Then sections and lightweight fakes.  
**Why:** Makes expected UI and service behaviors easy to verify and protects against regressions without brittle mocking setups.
