/**
 * The door between رفيق's Cloudflare tunnel and LM Studio on this PC.
 *
 * LM Studio answers anyone who can reach it, and the tunnel makes it
 * reachable from the whole internet, so the tunnel points here instead:
 * only requests carrying RAFEEQ_GATE_TOKEN (Masar's MASAR_LLM_TOKEN
 * secret) get through, and only to the endpoints askMentor uses.
 *
 * Masar's own copy of Khazna's gate (Exam-Vault/hu_pp_q/local-llm/gate.mjs):
 * a different port, token and tunnel, so the two apps never share a door.
 * Both reach the same LM Studio; this one lets a single request through at
 * a time and answers "busy" otherwise, so هاشمي's students keep the GPU.
 *
 * No dependencies — run with: node rafeeq-proxy.mjs   (see README.md)
 *
 * Not named gate.mjs on purpose: هاشمي's start-hashmi.ps1 looks for "*node*gate.mjs*"
 * to decide whether its own gate is up, and a match here would stop it from starting.
 */
import { createServer, request } from 'node:http';
import { timingSafeEqual } from 'node:crypto';
import { readFileSync } from 'node:fs';

// Values from .env next to this file, unless already set in the environment.
try {
  for (const line of readFileSync(new URL('.env', import.meta.url), 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z_]+)\s*=\s*(.*?)\s*$/);
    if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2];
  }
} catch {}

const TOKEN = process.env.RAFEEQ_GATE_TOKEN ?? '';
const PORT = Number(process.env.RAFEEQ_GATE_PORT ?? 8788);
const UPSTREAM = new URL(process.env.LMSTUDIO_URL ?? 'http://127.0.0.1:1234');
/** One GPU answers one student at a time well; a second waits its turn.
 *  Masar takes one at a time; askMentor treats "busy" like a timeout. */
const MAX_ACTIVE = Number(process.env.RAFEEQ_GATE_MAX_ACTIVE ?? 1);
const ALLOWED = new Set(['POST /v1/chat/completions', 'GET /v1/models']);

if (TOKEN.length < 32) {
  console.error('RAFEEQ_GATE_TOKEN is missing or shorter than 32 characters — see README.md');
  process.exit(1);
}

function authorized(header) {
  const given = Buffer.from(String(header ?? '').replace(/^Bearer\s+/i, ''));
  const want = Buffer.from(TOKEN);
  return given.length === want.length && timingSafeEqual(given, want);
}

let active = 0;

createServer((req, res) => {
  const path = (req.url ?? '').split('?')[0];
  const fail = (code, message) => {
    res.writeHead(code, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: { message } }));
  };
  if (!authorized(req.headers.authorization)) return fail(401, 'unauthorized');
  if (!ALLOWED.has(`${req.method} ${path}`)) return fail(404, 'not found');
  if (active >= MAX_ACTIVE) return fail(503, 'busy');

  active++;
  const started = Date.now();
  let done = false;
  const finish = () => {
    if (done) return;
    done = true;
    active--;
    console.log(`${new Date().toISOString()} ${req.method} ${path} ${res.statusCode} ${Date.now() - started}ms`);
  };
  res.on('close', finish);

  const headers = { ...req.headers, host: UPSTREAM.host };
  delete headers.authorization;
  const up = request(
    { hostname: UPSTREAM.hostname, port: UPSTREAM.port, path, method: req.method, headers },
    (upRes) => {
      res.writeHead(upRes.statusCode ?? 502, upRes.headers);
      upRes.pipe(res);
    },
  );
  up.on('error', (err) => {
    if (!res.headersSent) fail(502, `LM Studio unreachable: ${err.message}`);
    else res.destroy();
  });
  // The student closed the chat: stop the GPU too.
  res.on('close', () => up.destroy());
  req.pipe(up);
}).listen(PORT, '127.0.0.1', () => {
  console.log(`rafeeq gate on http://127.0.0.1:${PORT} -> ${UPSTREAM.origin}`);
});
