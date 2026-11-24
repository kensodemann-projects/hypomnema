import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, test } from "node:test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  doc,
  getDoc,
  setDoc,
  setLogLevel,
  updateDoc,
} from "firebase/firestore";

setLogLevel("silent");

const rules = readFileSync(
  join(dirname(fileURLToPath(import.meta.url)), "../../firestore.rules"),
  "utf8",
);

const entry = {
  subject: "Note",
  mood: 3,
  text: "hello",
  private: false,
  localDateTime: "2026-11-23T16:35:04",
};

let testEnv;

describe("journal entry rules", { concurrency: 1 }, () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: "kws-hypomnema",
      firestore: { rules },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  test("Alice can create, read, and update her own journal entry", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const reference = doc(alice, "users/alice/journalEntries/entry-1");

    await assertSucceeds(setDoc(reference, entry));
    await assertSucceeds(getDoc(reference));
    await assertSucceeds(updateDoc(reference, { text: "updated" }));
  });

  test("Alice cannot read or write Bob's journal entry", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const reference = doc(alice, "users/bob/journalEntries/entry-1");

    await assertFails(getDoc(reference));
    await assertFails(setDoc(reference, entry));
  });

  test("Bob cannot read or write Alice's journal entry", async () => {
    const alice = testEnv.authenticatedContext("alice").firestore();
    await assertSucceeds(
      setDoc(doc(alice, "users/alice/journalEntries/entry-1"), entry),
    );

    const bob = testEnv.authenticatedContext("bob").firestore();
    const reference = doc(bob, "users/alice/journalEntries/entry-1");

    await assertFails(getDoc(reference));
    await assertFails(setDoc(reference, entry));
    await assertFails(updateDoc(reference, { text: "nope" }));
  });

  test("a signed-out person cannot read or write a journal entry", async () => {
    const signedOut = testEnv.unauthenticatedContext().firestore();
    const reference = doc(signedOut, "users/alice/journalEntries/entry-1");

    await assertFails(getDoc(reference));
    await assertFails(setDoc(reference, entry));
  });
});
