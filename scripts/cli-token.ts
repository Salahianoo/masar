/**
 * An OAuth access token from the Firebase CLI's own login (`firebase login`),
 * for scripts that call Google REST APIs on this Mac. There is no gcloud or
 * application-default credential here, and firebase-admin refuses a user
 * credential for Firestore, so the scripts talk REST with this token instead.
 * The token is never printed.
 */
import {execSync} from "node:child_process";
import {readFileSync} from "node:fs";
import {createRequire} from "node:module";
import {homedir} from "node:os";
import {join} from "node:path";

export const PROJECT_ID = "masar-hackathon-jo-2026-salah";

export async function accessToken(): Promise<string> {
  const store = JSON.parse(readFileSync(join(homedir(), ".config/configstore/firebase-tools.json"), "utf8"));
  const refresh = store?.tokens?.refresh_token;
  if (!refresh) throw new Error("No Firebase CLI login found. Run `firebase login` first.");
  const cliRoot = execSync("npm root -g", {encoding: "utf8"}).trim();
  const api = createRequire(import.meta.url)(join(cliRoot, "firebase-tools/lib/api.js"));
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      client_id: api.clientId(),
      client_secret: api.clientSecret(),
      refresh_token: refresh,
      grant_type: "refresh_token",
    }),
  });
  if (!res.ok) throw new Error(`Token refresh failed (${res.status}). Try \`firebase login --reauth\`.`);
  return (await res.json()).access_token as string;
}
