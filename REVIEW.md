## Summary

Reviewed the resulting diff for [PR #16](https://github.com/kensodemann-projects/hypomnema/pull/16) (`4-gate-the-shell-behind-sign-in-and-add-sign-out` → `main`), which implements issue #4: gate the shell behind `AuthService.signedIn`, show a loading state then login or shell, and add phone/desktop sign-out. The auth gate, service API, and widget tests are solid and match the stated acceptance criteria. **Request changes** before merge: the PR title/body describe the opposite of the change, and `PLAN.md` still lists STEP-003 as unfinished while that work is already in the tree. SEC-001 is **won't fix**: the committed email is already public, and the emulator password is not used anywhere else. CLN-001 is **done**: `main` creates one `FirebaseAuthService` and passes it into `MainApp`. CLN-002 is **done**: `make emulators` imports `seed-data`. CLN-003 is **done**: `FirebaseAuthService` uses `{this._firebaseAuth}`, so callers pass `firebaseAuth:` and the field stays private.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     1 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     3 |
| 📚 Documentation gaps                      |     2 |
| ✅ Positive feedback                       |     2 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     2 |
| **Total**                                  |    10 |

## Findings

[SEC-001]

**Status:** Won't fix. The email is already public, and `password=tester` is an emulator-only password that is not used anywhere else. The `fakeHash` value cannot be imported into production Auth.

**Issue:** `seed-data/auth_export/accounts.json` commits a real email (`ken.sodemann@gmail.com`) and an emulator `passwordHash` that embeds the cleartext password (`password=tester`).

**Suggestion:** Use a disposable test identity only, for example `tester@example.com` / a dedicated non-personal password, and keep real-account exports out of git. If seed data must stay, document that it is emulator-only and rotate anything that matches a password used elsewhere.

**Why:** Emulator Auth exports intentionally store recoverable passwords. Even in a private repo, that pattern risks credential reuse and leaks personal identity into history that is hard to scrub later.

**Documentation:** https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html

[CLN-001]

**Status:** Done. `main` creates one `FirebaseAuthService` and passes it to `MainApp`. `authService` is required, so `build` no longer constructs a replacement.

**Issue:** `MainApp.build` constructs a new `FirebaseAuthService()` whenever `authService` is null:

```dart
final authService = this.authService ?? FirebaseAuthService();
```

**Suggestion:** Create the default service once (e.g. lazy field on `MainApp`, or construct it in `main` and pass it in) so rebuilds do not replace the gate’s stream instance.

**Why:** A new service yields a new `signedIn` stream. `StreamBuilder` would resubscribe and can briefly return to the progress state on otherwise unrelated rebuilds.

[CLN-002]

**Status:** Done. `make emulators` starts the Auth and Firestore emulators with `--import seed-data`.

**Issue:** `Makefile` adds `seed-data` and `web` targets that are outside issue #4’s auth-gate scope. `make emulators` still starts without `--import=./seed-data`, so the committed export is unused by the documented workflow.

**Suggestion:** Either wire import into `emulators` (and document credentials for local login), or drop the seed/`web` additions from this PR and land them separately.

**Why:** Unrelated Makefile noise makes the auth change harder to review and leaves seed data that looks supported but is never loaded.

[CLN-003]

**Status:** Done. `FirebaseAuthService({this._firebaseAuth})` initializes the private field. Call sites still pass `firebaseAuth:`, and the `prefer_initializing_formals` ignore is gone.

**Issue:** `FirebaseAuthService` uses `// ignore: prefer_initializing_formals` for the `firebaseAuth` → `_firebaseAuth` assignment.

**Suggestion:** Prefer a pattern that needs no ignore, e.g. keep the public parameter name and assign without triggering the lint, or document in a short comment *why* the public name must differ from the private field if the ignore stays.

**Why:** File-level ignores for mechanical lints tend to spread; a clearer constructor shape keeps the public `firebaseAuth:` API without silencing analysis.

[DOC-001]

**Issue:** The PR title (“Adds project planning, requirements, and UI mockups”) and body (“Removes preliminary authentication gate…”) do not describe this diff. The change **adds** the auth gate and sign-out for #4.

**Suggestion:** Retitle and rewrite the description to match the resulting diff, for example: gate the shell behind sign-in, add `signedIn`/`signOut` on `AuthService`, and cover phone/desktop sign-out in tests. Link #4.

**Why:** Reviewers and future archaeology will trust the wrong story; the current body contradicts both the branch name and the code.

[DOC-002]

**Issue:** `PLAN.md` marks STEP-001 and STEP-002 complete, leaves STEP-003’s status blank, and still describes pre-gate `MainApp`/`Shell` behavior—while the PR already implements STEP-003 (sign-out buttons and tests).

**Suggestion:** Mark STEP-003 complete (or remove `PLAN.md` from the merge if the team’s practice is to drop the plan once the work lands), and keep the PR description aligned with what remains in the tree.

**Why:** An unfinished plan next to finished code signals incomplete work and confuses anyone using `PLAN.md` as the source of truth.

[POS-001]

**Issue:** Auth state and sign-out stay behind `AuthService`; UI never talks to `FirebaseAuth` directly.

**Suggestion:** Keep this boundary as new shell features appear (profile, session-dependent routes).

**Why:** The injectable `AuthService` makes `MainApp` / shell tests deterministic and matches the project’s layered approach.

[POS-002]

**Issue:** `test/main_test.dart` and `test/data/services/auth_service_test.dart` cover waiting/signed-out/signed-in transitions, phone and desktop sign-out placement, successful sign-in, `AuthException` on sign-out (shell stays, no new error text), and stream identity for `signedIn`.

**Suggestion:** None required for this PR; this level of coverage is the right bar for the gate.

**Why:** The tests encode the issue #4 acceptance criteria and the PLAN decisions, so regressions in the gate will fail loudly.

[QST-001]

**Issue:** If `signedIn` errors (instead of emitting `true`/`false`), `_AuthGate` treats `snapshot.data == null` like “still waiting” and can show the progress indicator indefinitely.

**Suggestion:** Is silent forever-loading acceptable for v1, or should `snapshot.hasError` show login (or a minimal error surface) so a broken auth stream is recoverable?

**Why:** `authStateChanges()` is usually reliable, but an error path with no escape is hard to diagnose in the running app.

[QST-002]

**Issue:** Seed export includes Auth + empty Firestore metadata, but nothing in `firebase.json` / `make emulators` imports it.

**Suggestion:** Is the intent that developers manually run `firebase emulators:start --import=./seed-data`, or should import be the default local path now that seed data is committed?

**Why:** Without an agreed import path, the seed files are easy to forget and the personal test account is easy to misuse or leave stale.
