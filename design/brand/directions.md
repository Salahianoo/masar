# Masar brand directions — step 1

These are exploration boards. The symbols and mentor drawings are mood sketches, not production assets. Masar remains a separate brand from Khazna.

| Direction | Core idea | Palette | Arabic-first type | Mentor mood |
|---|---|---|---|---|
| A — The Flowing Route | A route bends with the student's pace | Primary `#24477B`, secondary `#44BFB7`, background `#F5F8F7` | IBM Plex Sans Arabic + Inter | Sea-glass guide; calm and curious |
| B — The Next Step | Progress happens one manageable step at a time | Primary `#584075`, secondary `#FF9277`, background `#FFF8F2` | IBM Plex Sans Arabic + Manrope | Folded bird companion; upbeat and warm |
| C — The Open Horizon | The student can choose a route forward | Primary `#21545A`, secondary `#D2DF72`, background `#F4F6E9` | IBM Plex Sans Arabic + DM Sans | Lantern guide; steady and focused |

The four mastery colors are identical on every board: unknown gray `#98A2AD`, weak red `#D94E5D`, medium amber `#E6A13A`, strong green `#2E9F72`. This follows the semantic mapping in `docs/CONTRACT.md` §7; the contract does not prescribe specific hex values.

The mockup was used for its approachable card layout and tone. Its placeholder colors were not carried over. Hashmi was used only to understand the desired production polish. None of these mentor sketches uses his white rounded body, red headwear, or outfit.

Editable sources are the three SVGs and `render-directions.js`. Regenerate the PNGs with Node.js and `sharp` available on the module path:

```sh
node design/brand/render-directions.js
```

Selection is pending Salah's choice. Brand tokens, a final icon, and mentor concepts are later steps.
