# PR #24 — add the firestore section to the firebase.json

**Branch:** `22-apply-firestore-rules-in-the-firebase-console` → `main`  
**Scope:** Resulting diff only (`firebase.json`, `firestore.rules`).

## Summary

This PR adds a `firestore` block that names `firestore.rules`, and the rules file matches the access model in issue #22: a signed-in person can read and write only `users/{their uid}` and everything under it, every signed-in person can read `prompts/{promptId}`, client writes to prompts are refused, and every other path stays denied. That is the setup the emulator uses when the rules file is on disk. The config file does not load. A trailing comma after `"rules"` makes `firebase.json` invalid, and the Firebase CLI stops before the emulator can read `firestore.rules`.

**Recommendation: request changes.**

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     0 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     1 |
| 🚨 Critical blockers                       |     1 |
| 💭 Questions for discussion                |     1 |
| **Total**                                  |     3 |

## Findings

### [BLK-001]

**Issue:** `firebase.json` has a trailing comma after `"rules": "firestore.rules"`. Strict JSON rejects it, and the Firebase CLI rejects it too. Loading the project config fails with `Trailing comma in object at 34:3` before the emulator starts.

**Suggestion:** Remove the comma:

```json
"firestore": {
  "database": "(default)",
  "rules": "firestore.rules"
}
```

**Why:** The CLI parses `firebase.json` with its JSON loader, which does not allow trailing commas. With this comma in place, `make emulators` never reaches the rules file, so the local `firestore.rules` are not applied. `database` and `rules` are the right pair of keys once the file parses: the emulator loads `rules` when that path exists, and it does not need `indexes` or `location` to enforce them.

### [POS-001]

**Issue:** N/A (positive).

**Suggestion:** `firestore.rules` is the ruleset from the user story. `rules_version = '2'` and `match /users/{userId}/{document=**}` cover the user document and nested documents, and `request.auth.uid == userId` keeps that tree private. `prompts/{promptId}` allows read for any signed-in client and refuses writes. Paths with no allow rule stay closed. Pointing `firebase.json` at that file is what makes the emulator enforce it instead of allowing every read and write.

**Why:** Local runs and a later rules deploy share one source of truth, and the rules grant only the access the story describes.

### [QST-001]

**Issue:** Issue #22 still says a human sets the rules in the Firebase console, and that this work does not add a rules file. This diff adds `firestore.rules`. The file configures the emulator and a future `firebase deploy --only firestore:rules`. It does not publish the rules to project `kws-hypomnema` by itself.

**Suggestion:** If the local file is now the source of truth, update issue #22 so it allows the rules file and names how production gets the same text (console publish or `firebase deploy --only firestore:rules`). The issue’s checks for signed-out denial, owner-only private data, and read-only prompts still need to be true on the `(default)` database, not only in the emulator.

**Why:** Merging the file protects emulator clients. Production stays on whatever rules are already published until someone deploys or pastes this text.
