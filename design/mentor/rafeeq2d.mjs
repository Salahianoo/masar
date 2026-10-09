// رفيق in 2D: builds one SVG per pose.
//   node design/mentor/rafeeq2d.mjs   → design/mentor/svg/{pose}.svg (then export PNGs at 512 and 1024)
// Colors: edit C. Shapes are in a 1024×1024 canvas.

import { mkdirSync, writeFileSync } from 'node:fs';

const C = {
  navy: '#24477B', navyDark: '#1B3866', teal: '#44BFB7', tealLight: '#5FF5E4',
  white: '#FFFFFF', shade: '#E3EAF1', face: '#FFF7EC', faceEdge: '#F1E3D2',
  eye: '#3A2418', cheek: '#F7A8AE', mouth: '#5B2E22', tongue: '#F27F86',
};

const DEFS = `
<defs>
  <linearGradient id="vinyl" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="${C.white}"/><stop offset=".65" stop-color="#F6F8FB"/><stop offset="1" stop-color="${C.shade}"/>
  </linearGradient>
  <linearGradient id="screen" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${C.face}"/><stop offset="1" stop-color="#F8EDDF"/>
  </linearGradient>
  <linearGradient id="cap" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#2E5A97"/><stop offset="1" stop-color="${C.navy}"/>
  </linearGradient>
  <linearGradient id="scarf" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#3FB3AB"/><stop offset="1" stop-color="${C.teal}"/>
  </linearGradient>
  <radialGradient id="glow"><stop offset="0" stop-color="${C.tealLight}" stop-opacity=".75"/><stop offset="1" stop-color="${C.tealLight}" stop-opacity="0"/></radialGradient>
  <radialGradient id="ground"><stop offset="0" stop-color="#1B3866" stop-opacity=".18"/><stop offset="1" stop-color="#1B3866" stop-opacity="0"/></radialGradient>
</defs>`;

const EDGE = 'stroke="#1B3866" stroke-opacity=".09" stroke-width="5"';

// An arm from a shoulder toward a hand point; drawn pointing down then rotated.
function arm(sx, sy, hx, hy, { finger = false } = {}) {
  const dx = hx - sx, dy = hy - sy;
  const len = Math.max(110, Math.hypot(dx, dy));
  const deg = (Math.atan2(dy, dx) * 180) / Math.PI - 90;
  const f = finger
    ? `<rect x="-17" y="${len - 6}" width="34" height="78" rx="17" fill="url(#vinyl)" ${EDGE}/>`
    : '';
  return `<g transform="translate(${sx} ${sy}) rotate(${deg.toFixed(1)})">
    <rect x="-40" y="-26" width="80" height="${len + 26}" rx="40" fill="url(#vinyl)" ${EDGE}/>${f}
  </g>`;
}

// ---------- face parts (face screen spans x 322..702, y 262..540) ----------
const eyesOpen = (lx = 0, ly = 0) => [440, 584].map((x) => `
  <ellipse cx="${x}" cy="398" rx="40" ry="48" fill="${C.eye}"/>
  <circle cx="${x + 12 + lx * 10}" cy="${380 + ly * 10}" r="14" fill="#fff"/>
  <circle cx="${x - 14}" cy="${418}" r="6" fill="#fff" fill-opacity=".8"/>`).join('');
const eyesHappy = () => [440, 584].map((x) =>
  `<path d="M${x - 38} 410 Q${x} 352 ${x + 38} 410" fill="none" stroke="${C.eye}" stroke-width="18" stroke-linecap="round"/>`).join('');
const brows = (tilt) => [[440, -1], [584, 1]].map(([x, s]) =>
  `<path d="M${x - 30} ${330 - tilt * s * -1} L${x + 30} ${330 + tilt * s * -1}" stroke="${C.eye}" stroke-width="12" stroke-linecap="round"/>`).join('');
const cheeks = () => [392, 632].map((x) => `<ellipse cx="${x}" cy="462" rx="34" ry="22" fill="${C.cheek}" fill-opacity=".6"/>`).join('');
const smile = (w = 56, d = 30, y = 468) =>
  `<path d="M${512 - w} ${y} Q512 ${y + d * 1.6} ${512 + w} ${y}" fill="none" stroke="${C.mouth}" stroke-width="15" stroke-linecap="round"/>`;
const openMouth = () => `
  <path d="M452 462 Q512 470 572 462 Q566 540 512 542 Q458 540 452 462 Z" fill="${C.mouth}"/>
  <path d="M478 518 Q512 500 546 518 Q536 540 512 541 Q488 540 478 518 Z" fill="${C.tongue}"/>`;
const oMouth = () => `<ellipse cx="530" cy="482" rx="18" ry="20" fill="none" stroke="${C.mouth}" stroke-width="12"/>`;
const wobble = () => `<path d="M476 482 Q494 470 512 480 Q530 490 548 478" fill="none" stroke="${C.mouth}" stroke-width="13" stroke-linecap="round"/>`;

// ---------- the body, front to back ----------
function figure({ arms = [], backArms = [], face, tilt = 0 }) {
  return `
  <ellipse cx="512" cy="948" rx="250" ry="34" fill="url(#ground)"/>
  <g transform="rotate(${tilt} 512 900)">
    ${backArms.join('')}
    <rect x="410" y="860" width="84" height="88" rx="40" fill="url(#vinyl)" ${EDGE}/>
    <rect x="530" y="860" width="84" height="88" rx="40" fill="url(#vinyl)" ${EDGE}/>
    <path d="M326 640 C326 586 390 560 512 560 C634 560 698 586 698 640 L712 820 C718 892 646 914 512 914 C378 914 306 892 312 820 Z" fill="url(#vinyl)" ${EDGE}/>
    <ellipse cx="420" cy="690" rx="46" ry="70" fill="#fff" fill-opacity=".7"/>
    <circle cx="590" cy="742" r="56" fill="${C.navy}" ${EDGE}/>
    <circle cx="590" cy="742" r="45" fill="none" stroke="${C.tealLight}" stroke-opacity=".5" stroke-width="4"/>
    <path d="M590 748 C590 732 574 728 578 716 C581 707 594 706 600 699" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round"/>
    <circle cx="602" cy="697" r="8" fill="${C.tealLight}"/>
    <path d="M590 750 C578 742 562 741 548 745 L548 772 C562 768 578 769 590 777 Z" fill="#fff"/>
    <path d="M590 750 C602 742 618 741 632 745 L632 772 C618 768 602 769 590 777 Z" fill="#DCE8F6"/>
    ${arms.join('')}
    <path d="M352 566 C420 600 604 600 672 566 L676 610 C604 646 420 646 348 610 Z" fill="url(#scarf)"/>
    <path d="M396 600 C392 650 380 690 400 712 L436 704 C428 680 436 640 440 612 Z" fill="${C.teal}"/>
    <rect x="252" y="172" width="520" height="420" rx="196" fill="url(#vinyl)" ${EDGE}/>
    <ellipse cx="350" cy="250" rx="60" ry="34" fill="#fff" transform="rotate(-25 350 250)"/>
    <rect x="322" y="262" width="380" height="278" rx="128" fill="url(#screen)" stroke="${C.faceEdge}" stroke-width="6"/>
    ${face}
    <g transform="rotate(-6 512 170)">
      <path d="M346 186 L346 246 C426 282 598 282 678 246 L678 186 Z" fill="${C.navyDark}"/>
      <path d="M512 92 L808 166 L512 240 L216 166 Z" fill="url(#cap)"/>
      <path d="M512 92 L808 166 L790 170 L512 104 L234 170 L216 166 Z" fill="#fff" fill-opacity=".14"/>
      <path d="M512 166 L790 172 C806 204 798 262 808 306" fill="none" stroke="${C.teal}" stroke-width="14" stroke-linecap="round"/>
      <circle cx="808" cy="326" r="52" fill="url(#glow)"/>
      <circle cx="808" cy="326" r="25" fill="${C.tealLight}"/>
      <circle cx="800" cy="318" r="8" fill="#fff" fill-opacity=".8"/>
      <circle cx="512" cy="166" r="16" fill="${C.teal}"/>
    </g>
  </g>`;
}

const L = [334, 640], R = [690, 640];   // shoulders
const down = { l: arm(...L, 286, 820), r: arm(...R, 738, 820) };

const POSES = {
  idle: figure({ arms: [down.l, down.r], face: eyesOpen() + cheeks() + smile() }),
  wave: figure({ arms: [down.l, arm(...R, 840, 430)], face: eyesOpen(0.3, 0) + cheeks() + smile(60, 34), tilt: -2 }),
  happy: figure({ arms: [arm(...L, 200, 450), arm(...R, 824, 450)], face: eyesHappy() + cheeks() + openMouth() }),
  thinking: figure({ arms: [down.l, arm(...R, 572, 548)], face: eyesOpen(-0.8, -1) + brows(-3) + cheeks() + oMouth(), tilt: 2 }),
  pointing: figure({ arms: [down.l, arm(...R, 880, 470, { finger: true })], face: eyesOpen(1, -0.6) + cheeks() + smile(48, 26) }),
  sorry: figure({ arms: [arm(...L, 226, 712), arm(...R, 798, 712)], face: eyesOpen(0, 0.5) + brows(-10) + cheeks() + wobble(), tilt: 2 }),
  head: null,
};
// avatar: the same idle face, cropped to the head and cap
POSES.head = POSES.idle;
const VIEW = { head: '160 40 720 720' };

mkdirSync(new URL('./svg/', import.meta.url), { recursive: true });
for (const [name, body] of Object.entries(POSES)) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${VIEW[name] ?? '0 0 1024 1024'}">${DEFS}${body}</svg>`;
  writeFileSync(new URL(`./svg/${name}.svg`, import.meta.url), svg);
}
console.log('wrote', Object.keys(POSES).join(', '));
