# Rafeeq 3D pose handoff

Approved character identity: `rafeeq-3d-idle-v2.png`. The seven Flutter assets are `idle`, `wave`, `happy`, `thinking`, `sorry`, `pointing`, and `head`.

Final transparent PNGs are in `app/assets/mentor/`: 512 × 512 logical assets, with matching 1024 × 1024 versions in `2.0x/`. Flutter selects the higher-resolution variant automatically. Amer can add this asset directory in `app/pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/mentor/
```

No package is needed. For example, use `Image.asset('assets/mentor/wave.png')`. `head.png` has padding for a circular avatar.

The 3D source PNGs are in `masters/`. `prompts.md` records generation instructions and references. `export_poses.py` reproduces the 512/1024 exports and `poses-preview.png`. The Khazna images under `references/hashmi-style-only/` are reference material, not app assets or Masar branding.
