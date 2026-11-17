# PR #24 — add the firestore section to the firebase.json

**Branch:** `22-apply-firestore-rules-in-the-firebase-console` → `main`  
**Scope:** Resulting diff only (`PLAN.md`, `REVIEW.md`, `firebase.json`).

## Summary

This PR adds PLAN-22 and a top-level `firestore` block in `firebase.json` for database `(default)`. The rules text in the plan is a sound default-deny model: owner-only `users/{userId}` and nested documents, authenticated read-only `prompts`, and no other client paths. The repository change does not match that plan. `firebase.json` is valid JSON, and it also sets `location`, `rules`, and `indexes`. The rules and indexes paths name files that are not in the tree, so a Firestore deploy fails while reading them, and STEP-001 is marked complete against a contract it does not satisfy.

**Recommendation: request changes.**

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     1 |
| 📚 Documentation gaps                      |     1 |
| ✅ Positive feedback                       |     1 |
| 🚨 Critical blockers                       |     1 |
| 💭 Questions for discussion                |     1 |
| **Total**                                  |     5 |

## Findings

### [BLK-001]

**Issue:** `firebase.json` does not implement the PLAN-22 contract, and STEP-001 is marked complete anyway. The contract (and the step’s **Change** section) add only `database: "(default)"` and leave `rules` and `indexes` unset, with no rules file in the repo. The diff adds `location`, `"rules": "firestore.rules"`, and `"indexes": "firestore.indexes.json"`. Neither `firestore.rules` nor `firestore.indexes.json` exists.

**Suggestion:** Make the block match the contract, and leave the step incomplete until that file and the console publish both match the acceptance criteria:

```json
"firestore": {
  "database": "(default)"
}
```

If repo-managed rules are now the intent, add those two files, put the contract rules in `firestore.rules`, and update PLAN-22 so `rules` and `indexes` are in scope. Do not mark STEP-001 complete while the file still disagrees with the contract.

**Why:** `firebase deploy` prepares Firestore by reading both paths. A missing indexes file fails with `File … does not exist`; a missing rules file fails with `Error reading rules file firestore.rules`. That prepare step runs before any rules release, so this config cannot deploy Firestore. `make emulators` still starts: the CLI warns that the rules file does not exist and falls back to allowing every read and write. That permissive emulator result happens to match the plan, but only alongside a missing-file warning the contract avoids by leaving `rules` unset. The acceptance criteria require the contract section in `firebase.json`. This diff does not meet them.

### [CLN-001]

**Issue:** The diff adds `REVIEW.md`, a prior review of this same PR. That write-up says `firebase.json` is invalid JSON because a comma is missing after `"(default)"`. The file on the branch parses (`python3 -m json.tool firebase.json` succeeds); the comma is present.

**Suggestion:** Drop `REVIEW.md` from the branch before merge. Review notes stay outside the product tree.

**Why:** A squash merge would put an incorrect review on `main` next to the config it misdescribes. Later readers will treat “invalid JSON” as the defect and miss the real mismatch (extra keys and missing files).

### [DOC-001]

**Issue:** STEP-001’s acceptance criteria require the `(default)` database in project `kws-hypomnema` to have the contract rules published, and they require a signed-out deny plus the signed-in `users` and `prompts` behavior. The Git diff cannot show that console publish or those checks. The plan’s opening still says `firebase.json` has no top-level `firestore` section, which is no longer true on this branch, and the step status is already **complete**.

**Suggestion:** Keep the problem statement in the past tense or as the pre-change state, and leave STEP-001 incomplete until both the `firebase.json` contract and the console publish are done. In the PR description, record that the rules were published on `(default)` and how the signed-out and signed-in cases were checked.

**Why:** The issue’s product outcome is the live ruleset, not the JSON key. Marking the step complete from the file edit alone hides the console half of “done.”

### [POS-001]

**Issue:** N/A (positive).

**Suggestion:** The rules in the plan are the right shape for the stated boundaries. `rules_version = '2'` with `match /users/{userId}/{document=**}` covers the user document and nested documents, and the `request.auth.uid == userId` check keeps that tree private. `prompts/{promptId}` is read-only for any signed-in client, with an explicit `allow write: if false`, and every other path stays denied because no allow rule grants it. The plan also says the console can still edit prompts because the console bypasses rules, and it keeps edit windows in the app.

**Why:** Client work for `users` and `prompts` can follow this model without guessing which paths are private, shared, or closed.

### [QST-001]

**Issue:** `"location": "nam5"` is not in the plan’s decisions or contract. The Firebase CLI uses `location` only when a deploy creates a database that does not already exist; if the field is omitted, that create path defaults to `nam5`.

**Suggestion:** Confirm that database `(default)` in `kws-hypomnema` is actually in `nam5`. If the database already exists, omit `location` so the file stays on the contract. If the field should stay, add one decision line in `PLAN.md` naming the region and why it is recorded.

**Why:** A wrong `location` does not move an existing database, but it documents a region the rest of the plan never agreed to, and a later create of a missing `(default)` database would use it.
