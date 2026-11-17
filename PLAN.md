# PLAN-22 — Apply Firestore rules in the Firebase console

Issue: [#22](https://github.com/kensodemann-projects/hypomnema/issues/22) (OPEN). Related to [#17](https://github.com/kensodemann-projects/hypomnema/issues/17).

`firebase.json` configures the Flutter platforms and the local Auth and Firestore emulators. It has no top-level `firestore` section. The repository has no rules file, so `make emulators` starts the Firestore emulator allowing every read and write. The app does not read or write a Firestore collection; `lib/main.dart` only sends debug builds to that emulator. Production rules for project `kws-hypomnema` live in the Firebase console.

**Decisions**

- Private data is the document `users/{userId}` and every document under it. The rules use `rules_version = '2'`, so `match /users/{userId}/{document=**}` covers that document and nested documents. Read and write are allowed only when `request.auth.uid` equals `userId`.
- Shared I'm Stuck prompts are the documents at `prompts/{promptId}`. Any signed-in person may read them. Client writes are refused. Editing the list in the Firebase console still works, because the console bypasses security rules.
- Any other path stays closed. Firestore denies a request that no allow rule grants.
- The repository change is a top-level `firestore` section in `firebase.json` for database `(default)`. `rules` and `indexes` stay unset.
- A human publishes the rules below in the Firebase console for project `kws-hypomnema`, database `(default)`.

**Out of scope**

- A rules file, an indexes file, and emulator tests.
- Client code that reads or writes `users` or `prompts`.
- Time-based edit windows. Those stay in the application.

**Contract**

`firebase.json` gains this section as a sibling of `flutter` and `emulators`, immediately before `emulators`:

```json
"firestore": {
  "database": "(default)"
}
```

The human publishes this rules text on the `(default)` database:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /prompts/{promptId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

**File order**

| Order | Step       | Status | Files          |
| ----- | ---------- | ------ | -------------- |
| 1     | [STEP-001] | complete | `firebase.json` |

**Commit gate**

The human commits. A spot-check does not replace the gate. `make check` already runs `test`.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit.

## [STEP-001] Add the Firestore section and publish the console rules

**Status:** complete

**Acceptance criteria:** `firebase.json` has the contract's top-level `firestore` section for database `(default)`. The `(default)` database in project `kws-hypomnema` has the contract's rules published. A signed-out person cannot read or write. A signed-in person can read and write only `users/{their uid}` and the documents under it, can read every `prompts/{promptId}` document, and cannot write prompts.

**Files**

1. `firebase.json` — add the top-level `firestore` section from the contract, immediately before `emulators`.

**Change**

Insert the contract's `firestore` object into `firebase.json` so the top-level keys are `flutter`, `firestore`, and `emulators`. Leave `rules` and `indexes` unset. Leave the repository without a rules file. The local emulator keeps allowing every read and write.

This step adds no test. The issue excludes emulator tests, and `firebase.json` has no test suite.

The file edit is the repository change. Before the step is validated, a human publishes the contract's rules text in the Firebase console: project `kws-hypomnema`, Firestore, database `(default)`, Rules. Publish that text as the database rules.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
