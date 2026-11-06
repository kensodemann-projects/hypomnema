# PLAN-2 — Connect Firebase Auth, Firestore, and the local emulator

Issue: [#2](https://github.com/kensodemann-projects/hypomnema/issues/2) (OPEN).

Related to [#1](https://github.com/kensodemann-projects/hypomnema/issues/1).

`lib/main.dart` `MainApp` shows the text `Hello World!` and depends only on `package:material_ui/material_ui.dart`. `pubspec.yaml` depends on the Flutter SDK and `material_ui`. The tree has no Firebase package, no `lib/firebase_options.dart`, no `android/app/google-services.json`, no `macos/Runner/GoogleService-Info.plist`, and no `firebase.json`. The Android application id in `android/app/build.gradle.kts` and the macOS bundle id in `macos/Runner/Configs/AppInfo.xcconfig` are both `com.example.hypomnema`. `android/app/src/main/AndroidManifest.xml` does not declare `INTERNET` (the debug and profile manifests do). `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` do not grant outgoing network or keychain access.

**Decisions**

- Connect Android and macOS with FlutterFire: `firebase_core`, `firebase_auth`, and `cloud_firestore`. `lib/main.dart` initializes Firebase. iOS, web, Windows, and Linux keep the current `MainApp` and do not call Firebase.
- Use the existing Firebase project. Register the Android and macOS apps on that project.
- The Android application id and macOS bundle id stay `com.example.hypomnema`.
- Enable Authentication with the Email/Password provider so users can be added in the Firebase console. The app does not sign in or create users.
- Debug runs (`kDebugMode`) use the Auth emulator on port 9099 and the Firestore emulator on port 8080. The Android emulator host is `10.0.2.2`. The macOS host is `localhost`. Profile and release builds use the production project and do not call the emulators.
- The debug Android manifest allows cleartext traffic so debug builds can reach the local emulator. The release manifest does not.

**Out of scope**

- Note documents and a notes data model.
- The login screen, the auth gate, and the signed-in shell.
- Firebase apps for iOS, web, Windows, and Linux.
- Account creation inside the app.
- Firestore security rules and deploying them.
- Changing the Android application id or the macOS bundle id.

**Contract**

- The home screen still shows `Hello World!`.
- Auth emulator port `9099`. Firestore emulator port `8080`.
- Debug Android host `10.0.2.2`. Debug macOS host `localhost`.

**File order**

| Order | Step       | Status | Files |
| ----- | ---------- | ------ | ----- |
| 1     | [STEP-001] |        | `pubspec.yaml`, then `pubspec.lock`, then `lib/firebase_options.dart`, then `android/settings.gradle.kts`, then `android/app/build.gradle.kts`, then `android/app/google-services.json`, then `android/app/src/main/AndroidManifest.xml`, then `macos/Runner/GoogleService-Info.plist`, then `macos/Runner.xcodeproj/project.pbxproj`, then `macos/Runner/DebugProfile.entitlements`, then `macos/Runner/Release.entitlements`, then `.firebaserc`, then `firebase.json`, then `lib/main.dart` |
| 2     | [STEP-002] |        | `lib/main.dart`, then `firebase.json`, then `android/app/src/debug/AndroidManifest.xml`, then `CONTRIBUTING.md` |

**Commit gate**

The human commits. A spot-check does not replace the gate. This repository does not define a build command. `CONTRIBUTING.md` lists `dart format .`, `flutter analyze`, and `flutter test`. `.github/workflows/flutter_ci.yml` gates on the format check and `flutter analyze`, and it leaves `flutter test` commented out because there is no `test/` directory. This plan does not add a test suite. Before each commit, these two commands must succeed with no warning or error:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
```

## [STEP-001] Connect the Firebase project

**Status:**

**Acceptance criteria:** The existing Firebase project is connected, with Authentication (Email/Password) and a Cloud Firestore database. Android and macOS builds start, `Firebase.initializeApp` completes, and the home screen still shows `Hello World!`.

**Files**

1. `pubspec.yaml` — add `firebase_core`, `firebase_auth`, and `cloud_firestore`.
2. `pubspec.lock` — lock the new dependencies from `flutter pub get`.
3. `lib/firebase_options.dart` — commit the FlutterFire-generated options for Android and macOS.
4. `android/settings.gradle.kts` — declare the Google services Gradle plugin the FlutterFire Android setup adds.
5. `android/app/build.gradle.kts` — apply that plugin in the app module.
6. `android/app/google-services.json` — commit the generated Android config. Keep the application id `com.example.hypomnema`.
7. `android/app/src/main/AndroidManifest.xml` — add `android.permission.INTERNET` so release builds can reach Firebase.
8. `macos/Runner/GoogleService-Info.plist` — commit the generated macOS config. Keep the bundle id `com.example.hypomnema`.
9. `macos/Runner.xcodeproj/project.pbxproj` — keep the FlutterFire edit that adds `GoogleService-Info.plist` to the Runner target.
10. `macos/Runner/DebugProfile.entitlements` — add `com.apple.security.network.client` and `keychain-access-groups` containing `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`. Leave the existing sandbox, JIT, and server keys in place.
11. `macos/Runner/Release.entitlements` — add the same network client and keychain group keys. Leave the existing sandbox key in place.
12. `.firebaserc` — set the existing Firebase project as `projects.default`. Write it from the project id in `lib/firebase_options.dart` when the CLI does not write this file.
13. `firebase.json` — keep the FlutterFire `flutter` platform map when the CLI writes one.
14. `lib/main.dart` — initialize Firebase for Android and macOS before `runApp`. Leave `MainApp` unchanged.

No test files. There is no `test/` directory, and the issue does not ask for tests.

**Change**

Activate the FlutterFire CLI and log in to Firebase. From the repository root, run `flutterfire configure --platforms=android,macos` and select the existing Firebase project. On that project, enable Authentication with the Email/Password provider and create a Cloud Firestore database if either is not already there. Commit the generated client config. Register only the Android and macOS apps.

In `lib/main.dart`, make `main` async. Call `WidgetsFlutterBinding.ensureInitialized()` first. When `defaultTargetPlatform` is `TargetPlatform.android` or `TargetPlatform.macOS`, call `Firebase.initializeApp` with `DefaultFirebaseOptions.currentPlatform`. Then call `runApp` with the existing `MainApp`. Take `WidgetsFlutterBinding`, `defaultTargetPlatform`, and `TargetPlatform` from `package:material_ui/material_ui.dart`. Do not sign in, create users, or read or write Firestore documents.

**Done when:** The acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.

## [STEP-002] Use the local Auth and Firestore emulators

**Status:**

**Acceptance criteria:** A debug run on the Android emulator and a debug run on macOS use the local Auth and Firestore emulators. Profile and release runs use the production project. The home screen still shows `Hello World!`.

**Files**

1. `lib/main.dart` — after a successful `Firebase.initializeApp`, connect debug runs to the emulators.
2. `firebase.json` — add the Auth, Firestore, and emulator UI configuration. Keep any existing `flutter` key.
3. `android/app/src/debug/AndroidManifest.xml` — allow cleartext traffic on debug builds.
4. `CONTRIBUTING.md` — document how to start the emulators before `flutter run`.

No test files. There is no `test/` directory, and the issue does not ask for tests.

**Change**

In `lib/main.dart`, when Firebase was initialized and `kDebugMode` is true, call `FirebaseAuth.instance.useAuthEmulator` and `FirebaseFirestore.instance.useFirestoreEmulator` before `runApp`. Use host `10.0.2.2` on Android and `localhost` on macOS. Use port `9099` for Auth and port `8080` for Firestore. Profile and release runs skip both calls.

Add this `emulators` object to `firebase.json`:

```json
{
  "auth": { "port": 9099 },
  "firestore": { "port": 8080 },
  "ui": { "enabled": true },
  "singleProjectMode": true
}
```

In `android/app/src/debug/AndroidManifest.xml`, set `android:usesCleartextTraffic="true"` on the application element so the debug manifest merger allows HTTP to the emulator. Do not set that flag on the main or release manifest.

In the Run section of `CONTRIBUTING.md`, state that local debug runs use these emulators and that they are started from the repository root with `firebase emulators:start --only auth,firestore` before `flutter run`.

**Done when:** The acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
