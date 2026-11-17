# PR #24 — add the firestore section to the firebase.json

**Branch:** `22-apply-firestore-rules-in-the-firebase-console` → `main`  
**Scope:** New `PLAN.md` (PLAN-22) and `firebase.json` Firestore configuration.

## Summary

This PR documents issue #22 and adds a top-level `firestore` block to `firebase.json`, aligned with a console-first rules workflow. The security model described in `PLAN.md` (per-user `users/{uid}/**`, read-only authenticated `prompts`, default deny) is sound for the stated product boundaries.

**Recommendation: request changes.** The committed `firebase.json` is not valid JSON and does not match the plan’s contract: it references `firestore.rules` and `firestore.indexes.json` that are not in the repository, while `PLAN.md` explicitly keeps `rules` and `indexes` unset. Either alignment error will block reliable `firebase` / `make emulators` use and fails the documented acceptance criteria for STEP-001.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     1 |
| 📚 Documentation gaps                      |     1 |
| ✅ Positive feedback                       |     1 |
| 🚨 Critical blockers                       |     2 |
| 💭 Questions for discussion                |     1 |
| **Total**                                  |     6 |

## Findings

### [BLK-001]

**Issue:** `firebase.json` is invalid JSON. After `"database": "(default)"` there is no comma before `"location"`.

**Suggestion:** Fix syntax and re-validate, for example:

```json
"firestore": {
  "database": "(default)",
  "location": "nam5",
  "rules": "firestore.rules",
  "indexes": "firestore.indexes.json"
}
```

Or, if following the plan contract (preferred for this PR):

```json
"firestore": {
  "database": "(default)"
}
```

**Why:** Invalid JSON prevents the Firebase CLI from reading project config; local validation (`python3 -m json.tool firebase.json`) currently fails.

### [BLK-002]

**Issue:** `firebase.json` sets `"rules": "firestore.rules"` and `"indexes": "firestore.indexes.json"`, but those files are absent from the PR (and from the repo on this branch).

**Suggestion:** Remove the `rules` and `indexes` keys to match `PLAN.md`, **or** add the files and update `PLAN.md` / issue scope if repo-managed rules are now intended. For the documented console-only workflow, unset paths are correct:

```json
"firestore": {
  "database": "(default)"
}
```

**Why:** Pointing at missing rule/index files commonly causes emulator start or `firebase deploy` failures, contradicting the plan’s goal of keeping the emulator permissive until rules live only in the console.

### [CLN-001]

**Issue:** The implementation diverges from the explicit contract in `PLAN.md` (lines 12–13, 25–28, 78–79): only `database: "(default)"` should be added; `rules` and `indexes` stay unset; rules files are out of scope.

**Suggestion:** Make `firebase.json` match the contract snippet in `PLAN.md`, or amend the plan and issue acceptance criteria if `location`, `rules`, and `indexes` are deliberate scope changes.

**Why:** Split brain between plan and config makes review and future steps unreliable; STEP-001 is marked **complete** while the file edit does not meet the stated acceptance criteria.

### [DOC-001]

**Issue:** Acceptance criteria require console rules on project `kws-hypomnema` to be published and behaviorally verified (signed-out deny, per-user `users`, read-only `prompts`). That work is not verifiable from the Git diff, and STEP-001 is already marked complete.

**Suggestion:** In the PR description or a follow-up comment to reviewers (not required in-repo), note that console rules were published and briefly how they were spot-checked; alternatively leave STEP-001 status as incomplete until validation is done.

**Why:** Repository changes alone do not enforce production Firestore rules; human/console steps are part of “done” for this issue.

### [POS-001]

**Issue:** N/A (positive).

**Suggestion:** `PLAN.md` clearly separates emulator vs production, documents default-deny with narrow allows, and uses `match /users/{userId}/{document=**}` appropriately for nested user data. Console bypass for prompt curation is called out explicitly.

**Why:** Future contributors can implement client reads/writes against a stable security story without guessing path semantics.

### [QST-001]

**Issue:** `"location": "nam5"` appears in `firebase.json` but is not mentioned in the plan contract or decisions.

**Suggestion:** Confirm whether this was added for deploy/CLI requirements or copy-paste from `firebase init`. If it is not required for emulator-only workflow, omit it to minimize config surface; if required, document it in `PLAN.md` under **Decisions**.

**Why:** Region/location in `firebase.json` affects provisioning expectations; unexplained fields tend to drift from team intent.