const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const out = __dirname;
const status = [
  ['UNKNOWN', '#98A2AD', '—'],
  ['WEAK', '#D94E5D', '28%'],
  ['MEDIUM', '#E6A13A', '54%'],
  ['STRONG', '#2E9F72', '82%'],
];

const directions = [
  {
    id: 'a', name: 'The Flowing Route', arabic: 'مساري، على راحتي',
    line: 'A continuous route bends around the learner, then moves forward.',
    primary: '#24477B', secondary: '#44BFB7', background: '#F5F8F7', ink: '#17304A',
    pair: 'IBM Plex Sans Arabic + Inter', mood: 'Quiet confidence · curious · clear',
    note: 'Sea-glass guide: light, fluid, attentive. Tapered silhouette; no costume.',
    mark: `<path d="M-94 58 C-82-65 -8-61 3-9 C14 45 98 36 96-55" fill="none" stroke="#fff" stroke-width="24" stroke-linecap="round"/><circle cx="-94" cy="58" r="14" fill="#fff"/><circle cx="96" cy="-55" r="17" fill="#77E2D5"/>`,
    mentor: `<ellipse cx="0" cy="152" rx="94" ry="18" fill="#123F57" opacity=".14"/>
      <path d="M-60 87 C-81 10 -60-92 7-104 C73-88 77 12 51 97 C25 136-30 136-60 87Z" fill="url(#tealBody)"/>
      <path d="M-50 52 C-65-14-47-73 7-88 C54-80 65-14 49 51" fill="none" stroke="#B4FFF4" stroke-width="7" opacity=".72"/>
      <circle cx="-20" cy="-11" r="7" fill="#17304A"/><circle cx="21" cy="-11" r="7" fill="#17304A"/>
      <path d="M-15 17 Q0 30 16 17" fill="none" stroke="#17304A" stroke-width="5" stroke-linecap="round"/>
      <path d="M-55 54 Q-95 49-96 13 M57 51 Q90 47 97 12" fill="none" stroke="#339E99" stroke-width="14" stroke-linecap="round"/>
      <circle cx="98" cy="-76" r="22" fill="#83E3D8"/><circle cx="98" cy="-76" r="8" fill="#fff"/>`,
  },
  {
    id: 'b', name: 'The Next Step', arabic: 'خطوة ورا خطوة',
    line: 'Progress is a sequence of approachable wins, never a race.',
    primary: '#584075', secondary: '#FF9277', background: '#FFF8F2', ink: '#332A46',
    pair: 'IBM Plex Sans Arabic + Manrope', mood: 'Bright optimism · momentum · warmth',
    note: 'Folded companion: sharp wing shape and soft expression; a fresh species.',
    mark: `<path d="M-105 61 H-42 V16 H20 V-32 H92" fill="none" stroke="#fff" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"/><circle cx="-105" cy="61" r="13" fill="#fff"/><path d="M79-45 L105-32 L79-19" fill="none" stroke="#FFBCA9" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/>`,
    mentor: `<ellipse cx="0" cy="153" rx="96" ry="17" fill="#322A46" opacity=".13"/>
      <path d="M-85 34 L-29-100 L3-45 L47-111 L75 28 L21 115 L-37 111Z" fill="url(#coralBody)"/>
      <path d="M-85 34 L-132 1 L-105 78 L-42 101" fill="#6F4C89"/>
      <path d="M75 28 L128-5 L100 77 L29 103" fill="#6F4C89"/>
      <path d="M-29-100 L2-45 L47-111 L20-21 L-5 6Z" fill="#FFC4A8" opacity=".9"/>
      <circle cx="-22" cy="19" r="6" fill="#332A46"/><circle cx="22" cy="19" r="6" fill="#332A46"/>
      <path d="M-14 43 Q0 56 15 43" fill="none" stroke="#332A46" stroke-width="5" stroke-linecap="round"/>`,
  },
  {
    id: 'c', name: 'The Open Horizon', arabic: 'اختار دربك',
    line: 'More than one way forward; the learner chooses the next turn.',
    primary: '#21545A', secondary: '#D2DF72', background: '#F4F6E9', ink: '#1E3D3E',
    pair: 'IBM Plex Sans Arabic + DM Sans', mood: 'Grounded focus · independence · calm',
    note: 'Lantern guide: tall faceted frame, inner glow, steady presence.',
    mark: `<path d="M0 79 V-17 M0-17 C-8-54-55-68-93-59 M0-17 C11-60 54-70 92-58" fill="none" stroke="#fff" stroke-width="22" stroke-linecap="round"/><circle cx="-93" cy="-59" r="14" fill="#fff"/><circle cx="92" cy="-58" r="17" fill="#E8F09E"/><path d="M0 79 L-17 56 M0 79 L17 56" fill="none" stroke="#fff" stroke-width="14" stroke-linecap="round"/>`,
    mentor: `<ellipse cx="0" cy="153" rx="84" ry="16" fill="#163C40" opacity=".16"/>
      <path d="M-42-110 L42-110 L75-45 L59 95 L0 132 L-59 95 L-75-45Z" fill="#21545A"/>
      <path d="M-32-89 L32-89 L53-40 L44 76 L0 107 L-44 76 L-53-40Z" fill="url(#lampGlow)"/>
      <path d="M-42-110 L-63-127 M42-110 L63-127" stroke="#21545A" stroke-width="13" stroke-linecap="round"/>
      <path d="M-57 34 Q-93 29-97-2 M57 34 Q93 29 97-2" stroke="#21545A" stroke-width="13" fill="none" stroke-linecap="round"/>
      <circle cx="-19" cy="-13" r="6" fill="#1E3D3E"/><circle cx="19" cy="-13" r="6" fill="#1E3D3E"/>
      <path d="M-13 15 Q0 25 13 15" fill="none" stroke="#1E3D3E" stroke-width="5" stroke-linecap="round"/>`,
  },
];

const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;');
const statusCells = status.map((s,i) => {
  const x = 85 + i*232;
  return `<g transform="translate(${x},763)"><rect width="211" height="86" rx="17" fill="#fff" stroke="#DCE2E4"/>
    <circle cx="24" cy="29" r="9" fill="${s[1]}"/><text x="42" y="35" class="small strong">${s[0]}</text>
    <text x="21" y="68" class="body" fill="${s[1]}">${s[2]}</text></g>`;
}).join('');

function svg(d) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1000" viewBox="0 0 1600 1000">
  <defs>
    <linearGradient id="tealBody" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#9AE9DD"/><stop offset=".5" stop-color="#54C8BE"/><stop offset="1" stop-color="#268E98"/></linearGradient>
    <linearGradient id="coralBody" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FFD0B4"/><stop offset=".5" stop-color="#FA987C"/><stop offset="1" stop-color="#D87578"/></linearGradient>
    <radialGradient id="lampGlow"><stop stop-color="#F3F7B2"/><stop offset=".65" stop-color="#D2DF72"/><stop offset="1" stop-color="#A7C272"/></radialGradient>
    <style>
      text{font-family:'Helvetica Neue',Arial,sans-serif;fill:${d.ink}}
      .eyebrow{font-size:22px;font-weight:700;letter-spacing:3px}
      .title{font-size:58px;font-weight:750;letter-spacing:-1.8px}
      .subtitle{font-size:24px;font-weight:400}
      .section{font-size:22px;font-weight:700;letter-spacing:1.5px}
      .body{font-size:25px;font-weight:500}
      .small{font-size:18px;font-weight:500}
      .strong{font-weight:700}
      .arabic{font-family:'SF Arabic','Arial',sans-serif;font-size:34px;font-weight:700;direction:rtl;unicode-bidi:plaintext}
    </style>
  </defs>
  <rect width="1600" height="1000" fill="${d.background}"/>
  <rect x="0" y="0" width="1600" height="16" fill="${d.primary}"/>
  <text x="84" y="78" class="eyebrow" fill="${d.primary}">MASAR / BRAND EXPLORATION</text>
  <text x="1510" y="78" text-anchor="end" class="eyebrow" fill="${d.secondary}">DIRECTION ${d.id.toUpperCase()}</text>
  <text x="82" y="168" class="title">${esc(d.name)}</text>
  <text x="84" y="212" class="subtitle">${esc(d.line)}</text>
  <line x1="84" y1="246" x2="1516" y2="246" stroke="#D7DFDD" stroke-width="2"/>
  <rect x="84" y="282" width="430" height="434" rx="30" fill="#fff" stroke="#DEE4E2"/>
  <text x="115" y="326" class="section">SYMBOL IDEA</text>
  <rect x="179" y="361" width="240" height="240" rx="54" fill="${d.primary}"/>
  <g transform="translate(299,481)">${d.mark}</g>
  <text x="299" y="650" text-anchor="middle" class="small">symbol only · scalable route</text>
  <rect x="542" y="282" width="467" height="434" rx="30" fill="#fff" stroke="#DEE4E2"/>
  <text x="574" y="326" class="section">PALETTE</text>
  <rect x="574" y="357" width="190" height="166" rx="21" fill="${d.primary}"/>
  <rect x="781" y="357" width="190" height="166" rx="21" fill="${d.secondary}"/>
  <text x="575" y="565" class="small strong">PRIMARY</text><text x="575" y="594" class="body">${d.primary}</text>
  <text x="782" y="565" class="small strong">SECONDARY</text><text x="782" y="594" class="body">${d.secondary}</text>
  <rect x="574" y="631" width="398" height="48" rx="14" fill="${d.background}" stroke="#CCD7D3"/>
  <text x="590" y="663" class="small">BACKGROUND  ${d.background}</text>
  <rect x="1037" y="282" width="479" height="434" rx="30" fill="#fff" stroke="#DEE4E2"/>
  <text x="1069" y="326" class="section">MENTOR MOOD / NOT FINAL</text>
  <g transform="translate(1275,488)">${d.mentor}</g>
  <text x="1069" y="655" class="small">${esc(d.mood)}</text>
  <text x="84" y="752" class="section">FIXED MASTERY STATUS COLORS</text>
  ${statusCells}
  <rect x="1051" y="763" width="465" height="167" rx="24" fill="#fff" stroke="#DCE2E4"/>
  <text x="1082" y="806" class="section">TYPE PAIRING</text>
  <text x="1082" y="844" class="body">${esc(d.pair)}</text>
  <text x="1082" y="888" class="arabic">${esc(d.arabic)}</text>
  <text x="84" y="961" class="small">${esc(d.note)}</text>
  <text x="1516" y="961" text-anchor="end" class="small">MASAR · STEP 1 / CHOOSE A DIRECTION</text>
  </svg>`;
}

(async () => {
  for (const d of directions) {
    const source = svg(d);
    fs.writeFileSync(path.join(out, `direction-${d.id}.svg`), source);
    await sharp(Buffer.from(source)).png().toFile(path.join(out, `direction-${d.id}.png`));
  }
})().catch(e => { console.error(e); process.exit(1); });
