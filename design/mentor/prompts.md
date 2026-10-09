# Rafeeq 3D pose generation

Approved character reference: `../mentor/rafeeq-3d-idle-v2.png` (also copied as `masters/idle.png`). Original 2D sheet: `reference-rafeeq2d-sheet.png`. The six Khazna references in `references/hashmi-style-only/` were used only for gesture and render quality. Their identity, clothing, red headwear and emblem are not part of Rafeeq or the Flutter exports.

Method: Codex built-in image generation, identity-preserving pose edits, transparent background. The tool did not expose a model ID or seed, so neither can be recorded. The raw outputs are in `masters/`. Re-export the app PNGs with `export_poses.py` (Pillow required).

For each pose, the exact generation prompt was the following template with `{name}` and `{pose}` replaced by the corresponding row below. Image 1 was always `rafeeq-3d-idle-v2.png`; image 2 was the listed Hashmi reference.

> Use case: identity-preserve character pose edit. Image 1 is the approved Rafeeq 3D character identity and exact style reference. Image 2 (Hashmi) is a POSE AND PRODUCTION-QUALITY reference only; do not transfer its outfit, colors, red headwear, chest logo or identity. Create ONE Rafeeq 3D render for the '{name}' pose. {pose} Preserve Rafeeq's clean cream face with absolutely no cheek blush or pink/red spots, friendly young male-coded face with simple dark-brown eyes and small defined brows, navy graduation cap with teal cord and glowing teal tassel, teal scarf, compact white body, and circular navy book emblem. Same premium soft-studio 3D clay/vinyl rendering, same camera angle and character scale as Image 1. Center full character with generous even padding; feet and cap fully visible. Genuinely transparent background. No labels, no added props, no extra characters, no text, no watermark.

| `{name}` | Image 2 | `{pose}` |
|---|---|---|
| wave | `references/hashmi-style-only/full-body.png` | Raise Rafeeq's right arm in a relaxed open-hand wave, with a small friendly smile. Keep the left arm resting naturally. |
| happy | `references/hashmi-style-only/happy.png` | Show delighted success: bright smiling open mouth and both arms lifted in a modest celebration, conveying encouragement rather than childish excitement. |
| thinking | `references/hashmi-style-only/thinking.png` | Thoughtful expression: one hand lightly at the chin, eyes looking slightly upward, one subtle raised eyebrow. Warm, curious, never worried. |

For the last three, replace `Create ONE Rafeeq 3D render for the '{name}' pose.` with `Create ONE Rafeeq 3D render for the '{name}' asset.` and use this wording after the `{pose}` sentence instead of the last four sentences above:

> Preserve Rafeeq's clean cream face with absolutely no cheek blush or pink/red spots, friendly young male-coded face with simple dark-brown eyes and small defined brows, navy graduation cap with teal cord and glowing teal tassel, teal scarf, compact white body where visible, and circular navy book emblem where the torso is visible. Same premium soft-studio 3D clay/vinyl rendering, same camera angle and character scale as Image 1. Center character with generous even padding; all visible parts fully in frame. Genuinely transparent background. No labels, no added props, no extra characters, no text, no watermark.

| `{name}` | Image 2 | `{pose}` |
|---|---|---|
| sorry | `references/hashmi-style-only/sorry.png` | Show a gentle apologetic expression: slightly raised inner brows, small sympathetic smile, one hand near the side of the head and the other open in a reassuring gesture. The expression should remain supportive, not sad. |
| pointing | `references/hashmi-style-only/pointing.png` | Raise Rafeeq's left arm to point clearly toward the upper right, with the other arm relaxed near his body. Friendly confident teaching expression. |
| head | `references/hashmi-style-only/head.png` | Create a HEAD-ONLY avatar portrait of Rafeeq: graduation cap, teal tassel, complete rounded white head frame and cream face centered, very small hint of teal scarf at bottom edge, no torso, no chest badge, no arms. Front three-quarter view, friendly subtle smile, visually balanced in a circular avatar crop. |

Exports: `app/assets/mentor/{pose}.png` at 512 × 512 and `app/assets/mentor/2.0x/{pose}.png` at 1024 × 1024, all RGBA with transparent backgrounds. `idle` uses the approved v2 render. `poses-preview.png` checks the set on light and dark cards.
