import {accessToken, PROJECT_ID} from "./cli-token.js";

type FirestoreValue = Record<string, unknown>;
type Write = {update: {name: string; fields: Record<string, FirestoreValue>};
  updateMask?: {fieldPaths: string[]}};
const resource = `projects/${PROJECT_ID}/databases/(default)/documents`;
const base = `https://firestore.googleapis.com/v1/${resource}`;

function encode(value: unknown): FirestoreValue {
  if (value === null || value === undefined) return {nullValue: null};
  if (typeof value === "string") return {stringValue: value};
  if (typeof value === "boolean") return {booleanValue: value};
  if (typeof value === "number") return Number.isInteger(value)
    ? {integerValue: String(value)} : {doubleValue: value};
  if (Array.isArray(value)) return {arrayValue: {values: value.map(encode)}};
  if (typeof value === "object") return {mapValue: {fields: fields(value as Record<string, unknown>)}};
  throw new Error(`Unsupported Firestore value: ${typeof value}`);
}
function fields(value: Record<string, unknown>): Record<string, FirestoreValue> {
  return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, encode(item)]));
}
export function write(path: string, value: Record<string, unknown>, mask?: string[]): Write {
  return {update: {name: `${resource}/${path}`, fields: fields(value)},
    ...(mask ? {updateMask: {fieldPaths: mask}} : {})};
}
export async function exists(path: string, token: string): Promise<boolean> {
  const response = await fetch(`${base}/${path}?mask.fieldPaths=__name__`,
    {headers: {authorization: `Bearer ${token}`}});
  if (response.status === 404) return false;
  if (!response.ok) throw new Error(`Firestore lookup ${path}: HTTP ${response.status} ${await response.text()}`);
  return true;
}
export async function getDocument(path: string, token: string): Promise<{fields?: Record<string, FirestoreValue>} | null> {
  const response = await fetch(`${base}/${path}`,
    {headers: {authorization: `Bearer ${token}`}});
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`Firestore lookup ${path}: HTTP ${response.status} ${await response.text()}`);
  return await response.json() as {fields?: Record<string, FirestoreValue>};
}
export async function commit(writes: Write[], providedToken?: string): Promise<void> {
  const token = providedToken ?? await accessToken();
  for (let index = 0; index < writes.length; index += 400) {
    const response = await fetch(`${base}:commit`, {
      method: "POST", headers: {authorization: `Bearer ${token}`, "content-type": "application/json"},
      body: JSON.stringify({writes: writes.slice(index, index + 400)}),
    });
    if (!response.ok) throw new Error(`Firestore commit batch ${index / 400 + 1}: HTTP ${response.status} ${await response.text()}`);
  }
}
