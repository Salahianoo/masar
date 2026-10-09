import {commit, write} from "./firestore-rest.js";

const projectId = "masar-hackathon-jo-2026-salah";
const config = {
  mentorName: "رفيق",
  mentorEnabled: false,
  mentorSource: "pc",
  dailyMentorLimit: 30,
} as const;

if (process.argv[2] !== "--write") {
  console.log("Preview config/app:", JSON.stringify(config, null, 2));
  console.log("Pass --write to seed the Masar Firebase project.");
} else {
  if (process.env.GOOGLE_CLOUD_PROJECT && process.env.GOOGLE_CLOUD_PROJECT !== projectId) {
    throw new Error(`Refusing to write to ${process.env.GOOGLE_CLOUD_PROJECT}; expected ${projectId}`);
  }
  await commit([write("config/app", config)]);
  console.log(`Seeded config/app in ${projectId}.`);
}
