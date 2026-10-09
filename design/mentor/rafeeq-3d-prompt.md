# Rafeeq 3D concept — single idle render

Source reference: `reference-rafeeq2d-sheet.png` (user-provided). The bottom-center idle panel supplied the main pose and proportions. This is one approval concept, not a full pose set or Flutter export.

Generation method: Codex built-in image generation, sketch-to-render, transparent background. The built-in tool did not expose a seed or model identifier, so those cannot be recorded.

Exact prompt:

> Use case: sketch-to-render. Input image: a user-provided character reference sheet; use the bottom-center 'idle' figure as the exact character identity and the other panels only to understand details. Create ONE full-body 3D studio render of this same character in a relaxed idle pose, front three-quarter view. Preserve the navy graduation cap with teal cord and glowing tassel, rounded white head framing the warm cream face, large dark-brown expressive eyes, small smile, soft pink cheeks, teal scarf, compact white body, short feet, and small circular navy-and-white book emblem on the chest. Premium stylized 3D animation quality, clean soft clay/vinyl materials, subtle fabric texture on scarf, soft studio lighting, crisp edges, friendly expression, consistent proportions. Character centered with generous even padding, genuinely transparent background. No labels, no sheet layout, no duplicate characters, no new accessories, no text, no watermark.

Output: `rafeeq-3d-idle-concept.png`, 1273 × 1236 RGBA. The master has not yet been resized or trimmed for Flutter.

## Face revision (v2)

Edit target: `rafeeq-3d-idle-concept.png`. Style-only reference: Salah's `hashmi head.png` from the separate Khazna project. The reference is deliberately not copied into the Masar repo.

Generation method: Codex built-in image edit, transparent background. Seed and model identifier were not exposed by the tool.

Exact prompt:

> Use case: precise-object-edit. Image 1 is the EDIT TARGET: Rafeeq, the navy-graduation-cap and teal-scarf 3D mentor. Image 2 is a facial-expression STYLE REFERENCE only: use the clean simple eye and smile language and polished 3D finish, not its identity, headwear, outfit, emblem, colors, or silhouette. Edit only Rafeeq's FACE: completely remove both pink/red cheek spots and all blush so the cream face has an even natural color; make the expression read as a friendly young male mentor with a slightly firmer, confident smile, subtly straighter small dark brows, and simple dark brown eyes. Keep him warm and approachable, not stern, adult 18–24 tone. Preserve exactly the existing Rafeeq body, white head frame, navy graduation cap with teal tassel, teal scarf, navy book badge, pose, camera angle, studio lighting, materials, framing, and genuinely transparent background. No red or pink marks on the cheeks. No red-and-white headwear, no Khazna logo, no added costume, no text, no duplicate characters.

Output: `rafeeq-3d-idle-v2.png`. This remains a concept awaiting Salah's approval, not a Flutter export.
