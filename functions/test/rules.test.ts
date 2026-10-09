import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {afterAll, beforeAll, describe, expect, it} from "vitest";
import {
  assertFails, assertSucceeds, initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {doc, getDoc, setDoc, updateDoc} from "firebase/firestore";

let environment: RulesTestEnvironment;

beforeAll(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-masar-rules",
    firestore: {host: "127.0.0.1", port: 8080,
      rules: readFileSync(resolve(process.cwd(), "../firestore.rules"), "utf8")},
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, "admins", "admin"), {}),
      setDoc(doc(db, "users", "alice"), {displayName: "Alice"}),
      setDoc(doc(db, "users", "bob"), {displayName: "Bob"}),
      setDoc(doc(db, "answerKeys", "q1"), {answer: "أ"}),
      setDoc(doc(db, "statsDaily", "2026-10-09"), {answers: 1}),
      setDoc(doc(db, "questions", "q1"), {text: "سؤال", flagged: false}),
      setDoc(doc(db, "subjects", "s1", "concepts", "c1"),
        {name: "النزيف", explanation: "شرح", weight: 0.4, order: 1, learners: 0, masterySum: 0}),
    ]);
  });
});

afterAll(async () => {
  await environment.cleanup();
});

describe("Firestore access", () => {
  it("hides answer keys and stats from students", async () => {
    const db = environment.authenticatedContext("alice").firestore();
    await assertFails(getDoc(doc(db, "answerKeys", "q1")));
    await assertFails(getDoc(doc(db, "statsDaily", "2026-10-09")));
    await assertSucceeds(getDoc(doc(db, "questions", "q1")));
  });

  it("isolates each student's private data and blocks every direct write", async () => {
    const db = environment.authenticatedContext("alice").firestore();
    await assertSucceeds(getDoc(doc(db, "users", "alice")));
    await assertFails(getDoc(doc(db, "users", "bob")));
    await assertFails(getDoc(doc(db, "users", "bob", "mastery", "s1")));
    await assertFails(setDoc(doc(db, "users", "alice", "mastery", "s1"), {readiness: 100}));
    await assertFails(updateDoc(doc(db, "questions", "q1"), {flagged: true}));
  });

  it("lets admins read private data and edit only permitted fields", async () => {
    const db = environment.authenticatedContext("admin").firestore();
    await assertSucceeds(getDoc(doc(db, "answerKeys", "q1")));
    await assertSucceeds(getDoc(doc(db, "users", "bob")));
    await assertSucceeds(updateDoc(doc(db, "questions", "q1"), {flagged: true}));
    await assertSucceeds(updateDoc(doc(db, "subjects", "s1", "concepts", "c1"), {name: "نزيف"}));
    await assertFails(updateDoc(doc(db, "subjects", "s1", "concepts", "c1"), {learners: 99}));
    expect((await getDoc(doc(db, "questions", "q1"))).data()?.flagged).toBe(true);
  });
});
