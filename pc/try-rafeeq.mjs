/**
 * Talks to رفيق on this PC with the real persona from docs/mentor-persona.md
 * and a sample first-aid concept, and measures speed: time to first word and
 * tokens per second.
 *
 *   node pc/try-rafeeq.mjs                         # straight to LM Studio (127.0.0.1:1234)
 *   node pc/try-rafeeq.mjs "سؤالك هون"
 *   RAFEEQ_URL=https://rafeeq.example.com RAFEEQ_TOKEN=... node pc/try-rafeeq.mjs   # through the tunnel and gate
 *
 * No dependencies. Node 18+.
 */
import { readFileSync } from 'node:fs';

const URL_BASE = (process.env.RAFEEQ_URL ?? 'http://127.0.0.1:1234').replace(/\/$/, '');
const TOKEN = process.env.RAFEEQ_TOKEN ?? '';
const MODEL = process.env.RAFEEQ_MODEL ?? 'qwen/qwen3.5-9b';
const question = process.argv[2] ?? 'مش فاهم الفرق بين النزيف الشرياني والوريدي';

const doc = readFileSync(new URL('../docs/mentor-persona.md', import.meta.url), 'utf8');
const template = doc.split('<!-- PROMPT:START -->')[1]?.split('<!-- PROMPT:END -->')[0]?.trim();
if (!template) throw new Error('PROMPT markers not found in docs/mentor-persona.md');

const grounding = `المفهوم: النزيف
الشرح: النزيف هو خروج الدم من الأوعية الدموية. الشرياني دمه أحمر فاتح ويخرج على شكل دفعات مع نبض القلب وهو الأخطر. الوريدي دمه أحمر داكن ويسيل بشكل مستمر. الشعيري يرشح ببطء من الجروح السطحية. أول إجراء لأي نزيف خارجي هو الضغط المباشر على الجرح بقطعة نظيفة.

س: أول إجراء عند النزيف الشرياني هو: أ) رفع الطرف ب) الضغط المباشر على الجرح ج) كمادة باردة د) إعطاء ماء
الجواب الصحيح: ب

س: الدم في النزيف الوريدي يكون أحمر فاتح ويخرج على شكل دفعات. (صح/خطأ)
الجواب الصحيح: خطأ`;

const system = template
  .replaceAll('{mentorName}', 'رفيق')
  .replaceAll('{subjectName}', 'ثقافة صحية و اسعافات أولية')
  .replaceAll('{studentState}', 'مستوى الطالب بهاد المفهوم: ضعيف (25%)، غلط آخر سؤالين.')
  .replaceAll('{grounding}', grounding);

const started = Date.now();
const res = await fetch(`${URL_BASE}/v1/chat/completions`, {
  method: 'POST',
  headers: { 'content-type': 'application/json', ...(TOKEN && { authorization: `Bearer ${TOKEN}` }) },
  body: JSON.stringify({
    model: MODEL,
    stream: true,
    temperature: 0.4,
    max_tokens: 500,
    reasoning_effort: 'none',
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: question },
    ],
  }),
});
if (!res.ok) {
  console.error(`HTTP ${res.status}: ${await res.text()}`);
  process.exit(1);
}

let raw = '';
let firstAt = 0;
let chunks = 0;
const decoder = new TextDecoder();
let buffer = '';
for await (const part of res.body) {
  buffer += decoder.decode(part, { stream: true });
  const lines = buffer.split('\n');
  buffer = lines.pop() ?? '';
  for (const line of lines) {
    if (!line.startsWith('data: ') || line.includes('[DONE]')) continue;
    const delta = JSON.parse(line.slice(6)).choices?.[0]?.delta?.content ?? '';
    if (!delta) continue;
    raw += delta;
    chunks++;
    const shown = raw.replace(/<think>[\s\S]*?(<\/think>\s*|$)/g, '');
    if (!firstAt && shown.trim()) firstAt = Date.now();
    process.stdout.write(delta);
  }
}

const total = (Date.now() - started) / 1000;
const streaming = firstAt ? (Date.now() - firstAt) / 1000 : 0;
console.log('\n\n---');
console.log(`first word after ${firstAt ? ((firstAt - started) / 1000).toFixed(1) : '—'}s · total ${total.toFixed(1)}s · ~${streaming > 0 ? (chunks / streaming).toFixed(1) : '—'} tokens/s`);
if (raw.includes('<think>')) console.log('⚠️ the model thought aloud: check that thinking is off in LM Studio');
