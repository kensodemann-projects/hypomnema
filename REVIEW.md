# PR #42 — Store journal entries for the signed-in user

Reviewed: resulting diff on `33-store-journal-entries-for-the-signed-in-user` → `main`  
Scope: journal domain/repository, Dart tests, Firestore rules emulator harness, CI/Makefile, docs alignment.

## Summary

This PR adds a well-scoped data layer for journal entries (create/update under `users/{uid}/journalEntries/{id}`), strong Dart-side validation and tests, and Node-based rules tests on a dedicated emulator port so they coexist with the dev suite. Feature-first layout matches project conventions; CI (`format_analyze_test`) passes. **Recommendation: approve.** The main follow-ups are intentional deferrals (no UI, no read path, coarse Firestore rules) and small test gaps—not merge blockers for this issue’s scope.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     1 |
| ⚡ Performance issues/optimizations        |     1 |
| 🧹 Code cleanup and maintainability        |     3 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     3 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     2 |
| **Total**                                  |    10 |

## Findings

### 🔒 Security concerns (immediate attention)

**[SEC-001]**

**Issue:** `firestore.rules` still allow any owner `write` (including `delete`) on all subcollections under `users/{userId}`, and the rules tests do not assert field shape. A modified client could persist invalid journal documents (e.g. missing `createdAt`, wrong types) or delete entries despite the app repository omitting delete.

**Suggestion:** Track a follow-up issue to tighten rules for `journalEntries/{entryId}` (required fields, `mood` range, immutable timestamps on update, optional delete denial) once product rules for delete and the 24-hour window are fixed.

**Why:** Defense in depth: Dart validation in this PR protects well-behaved clients; rules are the enforcement layer for tampered clients.

**Documentation:** [MDN Web Security](https://developer.mozilla.org/en-US/docs/Web/Security)

---

### ⚡ Performance issues/optimizations

**[PERF-001]**

**Issue:** CI installs `test/rules` dependencies with `npm ci` on every run and does not cache `test/rules/node_modules`, while Flutter dependencies are cached.

**Suggestion:** Add `actions/setup-node` `cache: npm` with `cache-dependency-path: test/rules/package-lock.json`, or cache the rules `node_modules` path explicitly.

**Why:** Rules tests add JDK + emulator startup; shaving npm install time keeps PR feedback snappy as the suite grows.

---

### 🧹 Code cleanup and maintainability

**[CLN-001]**

**Issue:** `InvalidJournalEntryException` and `JournalEntryRepositoryException` are marker types with no `message` or `toString` override.

**Suggestion:** Add a brief `toString` (or optional message) so logs and future UI error handling are easier to diagnose.

**Why:** Empty exception types are hard to tell apart in crash reports and integration tests that only capture `toString()`.

---

**[CLN-002]**

**Issue:** Repository tests cover signed-out `save` but not signed-out `update`, though `update` uses the same `_uid()` guard and PLAN calls out both paths.

**Suggestion:** Mirror the save test:

```dart
await expectLater(
  repository.update(entry: saved, subject: 'X', mood: 3, text: 'y', private: false),
  throwsA(isA<JournalEntryRepositoryException>()),
);
```

(with `currentUser` null on `_FakeFirebaseAuth`).

**Why:** Keeps repository auth behavior symmetric and prevents regressions if `_uid()` usage diverges between methods.

---

**[CLN-003]**

**Issue:** `FirestoreJournalEntryRepository.save` inlines the Firestore field map; a future read/load path will need the inverse mapping.

**Suggestion:** When adding `get`/`list`, introduce a single `JournalEntry` ↔ `Map<String, dynamic>` (or `DocumentSnapshot`) conversion used by save, update, and read.

**Why:** One serialization site avoids drift between write and read (e.g. `Timestamp` vs `DateTime`, field renames).

---

### ✅ Positive feedback

**[POS-001]**

**Issue:** N/A

**Suggestion:** Layering is clear: `JournalEntry` owns validation and `localDateTime` formatting; `JournalEntryRepository` is an interface with a Firestore implementation; injectable `clock` supports deterministic tests.

**Why:** Matches feature-first layout and keeps persistence details out of the domain model.

---

**[POS-002]**

**Issue:** N/A

**Suggestion:** Repository and domain tests follow the established Given/when/then naming, cover trim/reject paths, assert clock is not used on update, and use `fake_cloud_firestore` appropriately without pretending rules exist in unit tests.

**Why:** High confidence in the contract described in PLAN and REQUIREMENTS.

---

**[POS-003]**

**Issue:** N/A

**Suggestion:** `firebase.rules-test.json` uses Firestore port 8180 and Makefile documents the allowed duplicate-emulator notice—sensible ergonomics for developers who keep the dev suite on 8080.

**Why:** Reduces flaky local workflows and encodes that behavior in CI via `make test`.

---

### 💭 Questions for discussion

**[QST-001]**

**Issue:** Rules tests assert owner isolation for journal paths but not delete. Product/docs mention delete behavior later; rules still permit owner delete today.

**Suggestion:** Confirm whether a near-term rules change should deny `delete` on `journalEntries` before UI ships, or whether soft-delete is planned elsewhere.

**Why:** Aligns security rules with the repository’s “no delete” API and future 24-hour edit window.

---

**[QST-002]**

**Issue:** This PR deliberately does not wire the repository into `app/` or add read/stream APIs.

**Suggestion:** When picking up list/editor UI (#32 and related), decide whether the next PR adds `JournalEntry.fromFirestore` + repository `get`/`watch` in the same feature folder or splits data loading from UI.

**Why:** Avoids a large UI PR duplicating timestamp parsing or path conventions.