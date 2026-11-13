# PLAN-4 — Gate the shell behind sign-in and add sign-out

Issue: [#4](https://github.com/kensodemann-projects/hypomnema/issues/4) (OPEN).

Related to [#1](https://github.com/kensodemann-projects/hypomnema/issues/1).

`MainApp.build` in `lib/main.dart` sets `home` to `Shell`. `Shell` shows `PhoneScaffold` when the width is 600 or below and `DesktopScaffold` when the width is above 600. `PhoneScaffold` has an empty `AppBar` and the text `Phone`. `DesktopScaffold` has a 72-wide panel keyed `shell-side-panel` and the text `Desktop`. `AuthService` in `lib/data/services/auth_service.dart` exposes `signInWithEmailAndPassword` and `sendPasswordResetEmail`. `FirebaseAuthService`'s constructor parameter is the private `_firebaseAuth`, while `test/data/services/auth_service_test.dart` already passes `firebaseAuth:`. `LoginScreen` in `lib/ui/auth/login_screen.dart` calls the two existing methods and is not the app home. Nothing reads auth state, and nothing signs out.

## Decisions

- The commit gate is `make check`.
- Before `signedIn` emits, the gate shows a centered `CircularProgressIndicator` in a `Scaffold`. The shell stays hidden.
- A signed-in person signs out with an `IconButton` (`Icons.logout`, tooltip `Sign out`, key `shell-sign-out`) in the phone app bar, and the same button at the top of the desktop side panel.
- `AuthService` owns `signOut` and `Stream<bool> get signedIn`. The UI keeps using `AuthService` and does not call `FirebaseAuth`. `signedIn` is the cached `authStateChanges()` stream, mapped to `true` when the Firebase user is non-null. A restored session that emits `true` shows the shell on launch.
- `FirebaseAuthService` takes the public named parameter `firebaseAuth` that the existing service tests already pass.
- `signOut` maps `FirebaseAuthException` to `AuthException`, matching the other methods. The sign-out button awaits `signOut`, catches `AuthException`, and leaves the shell in place with no new error text.

## Out of scope

- Account creation stays outside the app.
- The login screen's forgot-password flow stays as it is.
- The shell placeholders stay the `Phone` and `Desktop` text.
- Firebase project setup, the emulator, and Firestore documents stay as they are.
- Light and dark theme behavior stays as it is.

## File order

| Order | Step       | Status | Files                                                                                                      |
| ----- | ---------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| 1     | [STEP-001] |        | `lib/data/services/auth_service.dart`, then `lib/ui/auth/login_screen.dart`, then `test/ui/auth/login_screen_test.dart`, then `test/data/services/auth_service_test.dart` |
| 2     | [STEP-002] |        | `lib/main.dart`, then `test/main_test.dart`                                                                |
| 3     | [STEP-003] |        | `lib/main.dart`, then `test/main_test.dart`                                                                |

## Commit gate

The human commits. A spot-check does not replace the gate. `make check` must succeed with no warning or error before that commit.

```bash
make check
```

## [STEP-001] Add sign-out and a signed-in stream to AuthService

**Status:**

**Acceptance criteria:** `AuthService.signOut` forwards to Firebase Auth and maps `FirebaseAuthException` to `AuthException`. `AuthService.signedIn` emits `true` for a Firebase user and `false` for null, in that order, from one stable stream instance.

**Files**

1. `lib/data/services/auth_service.dart` — public `firebaseAuth` parameter, `signOut`, and cached `signedIn`.
2. `lib/ui/auth/login_screen.dart` — `_PreviewAuthService` implements the new members.
3. `test/ui/auth/login_screen_test.dart` — `_RecordingAuthService` implements the new members.
4. `test/data/services/auth_service_test.dart` — fake `signOut` and `authStateChanges`, plus the new assertions.

**Change**

Add these members to `AuthService`:

```dart
Future<void> signOut();

Stream<bool> get signedIn;
```

Change `FirebaseAuthService` to `FirebaseAuthService({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth`. Keep `_auth` as `_firebaseAuth ?? FirebaseAuth.instance`.

Cache the stream on the service so each call returns the same instance:

```dart
late final Stream<bool> signedIn = _auth.authStateChanges().map(
  (user) => user != null,
);
```

Implement `signOut` with the same `try` / `on FirebaseAuthException` / `throw const AuthException()` shape as `signInWithEmailAndPassword`.

`_PreviewAuthService` and `_RecordingAuthService` implement `signOut` as an empty async method and `signedIn` as `const Stream<bool>.empty()`. The login screen does not call them.

On `_FakeFirebaseAuth`, record `signOut` calls, throw `exceptionToThrow` when it is set, and return a `StreamController<User?>` stream from `authStateChanges()`. A `User` fake can use `noSuchMethod`, matching `_FakeUserCredential`.

**Spot-check**

```bash
flutter test test/data/services/auth_service_test.dart test/ui/auth/login_screen_test.dart
```

- Existing sign-in and password-reset tests pass with `firebaseAuth:`.
- `signOut` is forwarded once, and a `FirebaseAuthException` from `signOut` throws `AuthException`.
- A user event then a null event on `authStateChanges` makes `signedIn` emit `true` then `false`.
- Login screen tests still pass.

**Done when:** the acceptance criteria hold, and `make check` succeeds with no warning or error.

**Commit:** `make check` succeeds with no warning or error.

## [STEP-002] Show login until the signed-in stream emits true

**Status:**

**Acceptance criteria:** With no `signedIn` event yet, `MainApp` shows the progress indicator and hides the login screen and the shell. After `false`, it shows `LoginScreen` and hides the shell. After a successful email-and-password sign-in, it shows the shell. The existing phone and desktop shell tests still pass for a stream that emits `true`, including widths 400, 600, 601, and 1200, and light and dark theme.

**Files**

1. `lib/main.dart` — `MainApp` takes an optional `AuthService`, and an auth gate chooses progress, `LoginScreen`, or `Shell`.
2. `test/main_test.dart` — a fake `AuthService`, updated shell tests, and gate tests.

**Change**

Import `auth_service.dart` and `login_screen.dart`. Widgets stay imported from `package:material_ui/material_ui.dart`.

`MainApp` keeps `const MainApp({super.key, this.authService})` with `final AuthService? authService`. `main` still calls `runApp(const MainApp())`. The home widget reads `authService ?? FirebaseAuthService()`.

Add a gate widget in `lib/main.dart` that listens to that service's `signedIn` stream:

- No data yet: a `Scaffold` whose body centers `CircularProgressIndicator(key: Key('auth-gate-progress'))`.
- `true`: the existing `Shell`.
- `false`: `LoginScreen(authService: authService)`.

Leave `Shell`, `PhoneScaffold`, and `DesktopScaffold` on their current layouts. `Shell()` can stay const in this step.

In `test/main_test.dart`, add a fake `AuthService` with a single `StreamController<bool>` stored on the fake. `signInWithEmailAndPassword` records the trimmed call the login screen already sends and then adds `true` to that controller. `sendPasswordResetEmail` and `signOut` can be empty.

Point every existing `MainApp` shell and theme test at a fake whose controller emits `true`, so `pumpAndSettle` ends on the shell. `const MainApp()` would construct `FirebaseAuthService` and touch Firebase.

Add these cases:

- The controller has not emitted. `pump` once (the progress indicator animates, so this case does not use `pumpAndSettle`). `auth-gate-progress` is present. `login-email`, `Phone`, and `Desktop` are absent.
- The controller emits `false` at a width of 400. After `pumpAndSettle`, `login-email` is present. `Phone`, `Desktop`, and `shell-side-panel` are absent.
- The controller emits `false` at a width of 400. Enter `person@example.com` and `secret`, tap `login-sign-in`, and let the fake emit `true`. After the following pump, `Phone` is present and `login-sign-in` is absent.

**Spot-check**

```bash
flutter test test/main_test.dart
```

- The waiting, signed-out, and sign-in cases match the acceptance criteria.
- Widths 400 and 600 still show the phone shell for a signed-in stream, and widths 601 and 1200 still show the desktop shell.
- Light and dark platform brightness still select the matching theme on the phone shell.

**Done when:** the acceptance criteria hold, and `make check` succeeds with no warning or error.

**Commit:** `make check` succeeds with no warning or error.

## [STEP-003] Add sign-out buttons that return to the login screen

**Status:**

**Acceptance criteria:** The phone shell shows one `shell-sign-out` icon button in the app bar. The desktop shell shows one `shell-sign-out` icon button in `shell-side-panel`. Tapping either button calls `signOut`. When that call emits `false` on `signedIn`, the login screen replaces the shell. When `signOut` throws `AuthException`, the shell stays and no error text is added.

**Files**

1. `lib/main.dart` — pass `AuthService` into `Shell` and both scaffolds, and add the shared sign-out button.
2. `test/main_test.dart` — phone and desktop sign-out cases, plus the `AuthException` case.

**Change**

Pass the gate's `AuthService` into `Shell`, `PhoneScaffold`, and `DesktopScaffold`.

Add one private button widget in `lib/main.dart`:

```dart
IconButton(
  key: const Key('shell-sign-out'),
  tooltip: 'Sign out',
  onPressed: () async {
    try {
      await authService.signOut();
    } on AuthException {
      // Stay on the shell. signedIn does not emit false.
    }
  },
  icon: const Icon(Icons.logout),
)
```

Put that button in `PhoneScaffold`'s `AppBar.actions`. Put the same button at the top of the desktop panel. Keep `shell-side-panel`, the panel width of 72, `surfaceContainerHigh`, the `Desktop` text, the phone `AppBar`, and the `Phone` text.

Extend the `test/main_test.dart` fake so `signOut` records the call. For the success cases it adds `false` to the controller. For the failure case it throws `AuthException` and adds nothing.

Add these cases, each starting from a controller that has emitted `true`:

- Width 400: one `shell-sign-out`, and it is inside the `AppBar`. `shell-side-panel` is absent. Tap the button. `signOut` was called once. `login-email` is present and `Phone` is absent.
- Width 601: one `shell-sign-out`, and it is a descendant of `shell-side-panel`. The `AppBar` is absent. Tap the button. `signOut` was called once. `login-email` is present and `Desktop` is absent.
- Width 400: `signOut` throws `AuthException`. After the tap, `Phone` is present, `login-email` is absent, and no new error text is shown.

**Spot-check**

```bash
flutter test test/main_test.dart
```

- The phone tap, the desktop tap, and the `AuthException` tap match the acceptance criteria.
- The step 002 gate tests and the shell layout and theme tests still pass.

**Done when:** the acceptance criteria hold, and `make check` succeeds with no warning or error.

**Commit:** `make check` succeeds with no warning or error.
