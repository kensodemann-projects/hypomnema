# PLAN-33 — Store journal entries for the signed-in user

Issue: [#33](https://github.com/kensodemann-projects/hypomnema/issues/33) (OPEN).

Related to [#32](https://github.com/kensodemann-projects/hypomnema/issues/32).

Nothing in the app writes a journal entry. `main` initializes `FirebaseFirestore` and points debug builds at the emulator, and `firestore.rules` lets a signed-in user read and write every document under `users/{their uid}`. `Makefile`'s `test` target runs `flutter test`, and `.github/workflows/flutter_ci.yml` runs that same command. There is no `lib/features/journal/` code and no rules test.

**Decisions**

- The local date and time is one string field, `localDateTime`, formatted `YYYY-MM-DDTHH:mm:ss` from the device's local clock at first save, with no offset. `createdAt` is a Firestore `Timestamp` of that same instant.
- A stored subject and the stored text are trimmed. A subject or text that is empty after trim is rejected. `mood` is an `int` from 1 to 5. `private` is a bool.
- The path uid is the signed-in user's uid. The document does not store a uid field. Document ids come from Firestore's auto-id.
- Dart repository tests use `fake_cloud_firestore` 4.5.0, the release that matches `cloud_firestore` 7.1.0, with no security rules loaded. Emulator tests are Node tests on `@firebase/rules-unit-testing` and `node --test`, and they run as part of `make test`.
- `firestore.rules` stays as it is. An owner write at the rules layer still includes delete. The application repository exposes save and update only.

**Out of scope**

- Journal list, details, editor, privacy display, and Show Content.
- Loading, listing, or streaming entries.
- The 24-hour edit window.
- I'm Stuck prompts and the `prompts` collection.
- Editing `firestore.rules`, including a delete denial or a timestamp freeze.
- Wiring the repository into `MainApp` or `main`.
- Publishing rules with `make publish-rules`.

**Contract**

A document at `users/{uid}/journalEntries/{entryId}` stores:

| Field | Value |
| --- | --- |
| `subject` | Trimmed string. Empty or whitespace-only is rejected. |
| `mood` | Whole number from 1 to 5. |
| `text` | Trimmed string. Empty or whitespace-only text is rejected. |
| `private` | `true` or `false`. |
| `localDateTime` | `YYYY-MM-DDTHH:mm:ss`, no offset, from the local clock at first save. |
| `createdAt` | Firestore `Timestamp` of that same instant. |

An update writes `subject`, `mood`, `text`, and `private` only. `localDateTime` and `createdAt` stay as first saved.

**File order**

| Order | Step | Status | Files |
| --- | --- | --- | --- |
| 1 | [STEP-001] | | `pubspec.yaml`, then `pubspec.lock`, then `lib/features/journal/domain/journal_entry.dart`, then `lib/features/journal/data/journal_entry_repository.dart`, then `test/features/journal/domain/journal_entry_test.dart`, then `test/features/journal/data/journal_entry_repository_test.dart` |
| 2 | [STEP-002] | | `test/rules/package.json`, then `test/rules/package-lock.json`, then `test/rules/journal_entries.test.js`, then `.gitignore`, then `Makefile`, then `.github/workflows/flutter_ci.yml` |

**Commit gate**

The human commits. A spot-check does not replace the gate. `make check` runs `format-check`, `analyze`, and `test`. From [STEP-002] onward, `test` also runs the Firestore emulator rules tests, so `make check` needs Node, npm, a JDK, and the Firebase CLI that [STEP-002] installs through `test/rules`.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit.

## [STEP-001] Save and update a journal entry

**Status:**

**Acceptance criteria:** A saved entry stores the contract fields under `users/{uid}/journalEntries/{entryId}`. A mood outside 1–5, or text that is empty after trim, is rejected and writes nothing. Updating changes subject, mood, text, and private, and leaves `localDateTime` and `createdAt` as first saved. The repository exposes no delete.

**Files**

1. `pubspec.yaml` — add dev dependency `fake_cloud_firestore: 4.5.0`.
2. `pubspec.lock` — lock that dependency.
3. `lib/features/journal/domain/journal_entry.dart` — the entry, its validation, and the local date-time format.
4. `lib/features/journal/data/journal_entry_repository.dart` — Firestore save and update for the signed-in user.
5. `test/features/journal/domain/journal_entry_test.dart` — validation, formatting, and revise.
6. `test/features/journal/data/journal_entry_repository_test.dart` — the stored document and the update.

**Change**

`JournalEntry` holds `id`, `subject`, `mood`, `text`, `private`, `localDateTime`, and `createdAt` (`DateTime` in UTC). `JournalEntry.create` takes those inputs plus a non-empty `id` and the clock instant `now`. It formats `localDateTime` from `now.toLocal()` as `YYYY-MM-DDTHH:mm:ss` with zero-padded parts, and stores `createdAt` as `now.toUtc()`. `InvalidJournalEntryException` is thrown when `id` is empty, `subject` is empty after trim, `mood` is outside 1–5, or `text` is empty after trim. Subject and text are stored trimmed. `revise` takes subject, mood, text, and private, runs the same validation, and returns a new entry with the same `id`, `localDateTime`, and `createdAt`. This file is the only place that formats `localDateTime`.

`JournalEntryRepository` is an interface with `save` and `update` only. `save` takes subject, mood, text, and private. `update` takes the existing `JournalEntry` plus the same four fields. `FirestoreJournalEntryRepository` takes `FirebaseFirestore`, `FirebaseAuth`, and a `DateTime Function()` clock that defaults to `DateTime.now`. The uid is `FirebaseAuth.currentUser?.uid`. When that is null, `save` and `update` throw `JournalEntryRepositoryException` and write nothing. Otherwise the path is `users/{uid}/journalEntries/{entryId}`. `save` takes the id from `collection.doc().id`, calls `JournalEntry.create` with one clock reading, and `set`s the contract fields. `createdAt` is `Timestamp.fromDate`. `update` calls `entry.revise` and does not read the clock. It `update`s `subject`, `mood`, `text`, and `private`. It does not write `localDateTime` or `createdAt`. Both methods return the `JournalEntry`.

Tests use the `Given ..., when ..., then ...` names already used in `test/features/auth/data/auth_service_test.dart`. Domain tests assert:

- `DateTime(2026, 11, 23, 16, 35, 4)` becomes `localDateTime` `2026-11-23T16:35:04` and a UTC `createdAt` of that instant.
- Surrounding spaces are trimmed off the subject and off the text.
- An empty subject is rejected with `InvalidJournalEntryException`. A whitespace subject is rejected the same way.
- Moods 1 and 5 are accepted. Moods 0 and 6 throw `InvalidJournalEntryException`.
- Empty and whitespace-only text throw `InvalidJournalEntryException`.
- An empty id throws `InvalidJournalEntryException`.
- `revise` replaces subject, mood, text, and private, and keeps `id`, `localDateTime`, and `createdAt`.

Repository tests build `FirestoreJournalEntryRepository` with `FakeFirebaseFirestore` and no security rules, a `FirebaseAuth` fake in the style of `_FakeFirebaseAuth` in `test/features/auth/data/auth_service_test.dart` whose `currentUser.uid` is `user-1`, and a clock. They read the document back from the fake. Assert:

- `save` writes `users/user-1/journalEntries/{id}` with the contract fields, `mood` as an int, and `createdAt` as a `Timestamp` of the clock instant. The returned entry's id is that document id.
- Two saves write two document ids.
- A whitespace subject makes `save` throw `InvalidJournalEntryException` and leaves the fake empty.
- A signed-out user (`currentUser` null) makes `save` throw `JournalEntryRepositoryException` and leaves the fake empty.
- Mood 0 and whitespace text make `save` throw `InvalidJournalEntryException` and leave the fake empty.
- After `save` at the first clock instant, `update` with a later clock instant changes subject, mood, text, and private, leaves `localDateTime` and `createdAt` on the first instant, and leaves exactly one document.
- `update` with a whitespace subject throws `InvalidJournalEntryException` and leaves the stored subject unchanged.
- The clock is called once for `save` and is not called for `update`.

**Spot-check**

```bash
flutter test test/features/journal
```

- Domain and repository tests pass, including the rejected mood and text cases and the unchanged timestamps.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.

## [STEP-002] Lock journal entry rules with emulator tests

**Status:**

**Acceptance criteria:** With the Firestore emulator enforcing `firestore.rules`, a signed-in user can read and write only their own `users/{uid}/journalEntries/{entryId}` documents. Another signed-in user cannot read or write those documents. A signed-out person cannot read or write them.

**Files**

1. `test/rules/package.json` — private Node package for the rules tests.
2. `test/rules/package-lock.json` — lock those dependencies.
3. `test/rules/journal_entries.test.js` — emulator tests for the journal entry path.
4. `.gitignore` — ignore `test/rules/node_modules/`.
5. `Makefile` — run the rules tests from the `test` target.
6. `.github/workflows/flutter_ci.yml` — install the JDK, Node, and the rules-test dependencies, then run `make test`.

**Change**

Add `test/rules/package.json` with `"private": true`, `"type": "module"`, and a `test` script of `node --test journal_entries.test.js`. Dev dependencies are `@firebase/rules-unit-testing`, `firebase`, and `firebase-tools`. Commit the lockfile from `npm install` in that directory. Ignore `test/rules/node_modules/`.

`journal_entries.test.js` reads `firestore.rules` from the repository root and passes those rules to `initializeTestEnvironment` for project `kws-hypomnema`. It uses the Firestore emulator host that `firebase emulators:exec` sets. It does not point at production. `clearFirestore` runs before each test. The tests use `authenticatedContext` and `unauthenticatedContext` with `assertSucceeds` and `assertFails`. They do not check field validation, because the rules do not.

- Alice (`authenticatedContext('alice')`) can `setDoc`, `getDoc`, and `updateDoc` on `users/alice/journalEntries/entry-1`.
- Alice cannot `getDoc` or `setDoc` on `users/bob/journalEntries/entry-1`. A denied read fails the call; it does not look like a missing document.
- After Alice writes `users/alice/journalEntries/entry-1`, Bob (`authenticatedContext('bob')`) cannot `getDoc`, `setDoc`, or `updateDoc` that document.
- A signed-out context cannot `getDoc` or `setDoc` `users/alice/journalEntries/entry-1`.

`Makefile`'s `test` target still runs `flutter test` first. It then runs, from the repository root:

```bash
npm --prefix test/rules exec -- firebase emulators:exec --only firestore --project kws-hypomnema "npm --prefix test/rules test"
```

That uses the `firebase-tools` dependency in `test/rules`, `firebase.json`, and `firestore.rules`. The Auth emulator stays unused because the rules-unit-testing contexts set `request.auth`.

In `.github/workflows/flutter_ci.yml`, before the test step, set up Temurin 21, set up Node 22, and run `npm ci --prefix test/rules`. Change the `Run Tests` step from `flutter test` to `make test`. Leave the format and analyze steps as they are. Do not edit `firestore.rules`.

**Spot-check**

```bash
npm --prefix test/rules exec -- firebase emulators:exec --only firestore --project kws-hypomnema "npm --prefix test/rules test"
```

- Alice's read and write succeed, and Bob's and the signed-out access fail.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
