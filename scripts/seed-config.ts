import {applicationDefault, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

const projectId = "masar-hackathon-jo-2026-salah";
const config = {
  mentorName: "رفيق",
  mentorEnabled: true,
  mentorSource: "cloud",
  dailyMentorLimit: 30,
} as const;

if (process.argv[2] !== "--write") {
  console.log("Preview config/app:", JSON.stringify(config, null, 2));
  console.log("Pass --write to seed the Masar Firebase project.");
} else {
  if (process.env.GOOGLE_CLOUD_PROJECT && process.env.GOOGLE_CLOUD_PROJECT !== projectId) {
    throw new Error(`Refusing to write to ${process.env.GOOGLE_CLOUD_PROJECT}; expected ${projectId}`);
  }
  initializeApp({credential: applicationDefault(), projectId});
  await getFirestore().doc("config/app").set(config);
  console.log(`Seeded config/app in ${projectId}.`);
}
