# Masar visuals

## App icon: book + path
Sources: `design/icon/masar-icon.svg` (full icon), `android-foreground.svg`, `android-monochrome.svg`.
Exports: `app/assets/icon/icon-1024.png` (iOS, no transparency), `android-foreground.png`,
`android-monochrome.png`. The Android adaptive background is the solid color `#24477B`.

| Part | Color |
|---|---|
| Background (radial gradient, center at 30% / 20%) | `#2E5A97` → `#1B3866` |
| Background, flat (Android, splash) | `#24477B` |
| Path line + left page | `#FFFFFF` |
| Right page | `#E4EEF9` |
| Page lines | `#9FB6D6` |
| Spine | `#1B3866` |
| Goal dot | `#5FF5E4` (glow: `#5FF5E4` at 60% → 0%, highlight: white at 70%) |

## رفيق (the mentor), 2D
Sources: `design/mentor/rafeeq2d.mjs` builds `design/mentor/svg/{pose}.svg`.
Exports: `app/assets/mentor/{pose}.png` (512) and `app/assets/mentor/2.0x/{pose}.png` (1024), transparent.
Poses: `idle`, `wave`, `happy`, `thinking`, `pointing`, `sorry`, `head` (round avatar).

Mentor colors: navy `#24477B` / `#1B3866`, teal `#44BFB7`, glow `#5FF5E4`, body white → `#E3EAF1`,
face `#FFF7EC`, eyes `#3A2418`, cheeks `#F7A8AE`.

## For Amer (pubspec.yaml)
```yaml
flutter:
  assets:
    - assets/mentor/
    - assets/icon/
```
`Image.asset('assets/mentor/wave.png')` picks the 2.0x file on high-density screens automatically.
For the launcher icon (dev_dependency `flutter_launcher_icons`):
```yaml
flutter_launcher_icons:
  ios: true
  android: true
  image_path: assets/icon/icon-1024.png
  adaptive_icon_background: "#24477B"
  adaptive_icon_foreground: assets/icon/android-foreground.png
  adaptive_icon_monochrome: assets/icon/android-monochrome.png
  remove_alpha_ios: true
```
