"""Prepare approved Rafeeq masters as resolution-aware Flutter PNG assets."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
MASTERS = ROOT / "design" / "mentor" / "masters"
ASSETS = ROOT / "app" / "assets" / "mentor"
POSES = ["idle", "wave", "happy", "thinking", "sorry", "pointing", "head"]


def clean_alpha(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    alpha = im.getchannel("A").filter(ImageFilter.MedianFilter(3))
    alpha = alpha.point(lambda value: 0 if value < 20 else value)
    im.putalpha(alpha)
    return im


def make_export(name: str) -> Image.Image:
    source = clean_alpha(Image.open(MASTERS / f"{name}.png"))
    bbox = source.getchannel("A").getbbox()
    if not bbox:
        raise ValueError(f"Empty alpha in {name}")
    source = source.crop(bbox)
    # Keep the head, cap corners and tassel inside a circular Flutter avatar.
    target = 720 if name == "head" else 898
    scale = min(target / source.width, target / source.height)
    size = (round(source.width * scale), round(source.height * scale))
    subject = source.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    x = (1024 - size[0]) // 2
    y = (1024 - size[1]) // 2
    canvas.alpha_composite(subject, (x, y))
    return canvas


def preview(exports: dict[str, Image.Image]) -> None:
    width, height = 1760, 980
    board = Image.new("RGB", (width, height), "#E9EEF0")
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 25)
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 38)
    draw.text((55, 32), "RAFEEQ / 3D POSES", font=title_font, fill="#17304A")
    draw.text((55, 79), "Transparent Flutter assets · matching scale · 512px + 1024px", font=font, fill="#52616F")
    for i, name in enumerate(POSES):
        col, row = i % 4, i // 4
        x = 54 + col * 423
        y = 145 + row * 405
        bg = "#FFFFFF" if row == 0 else "#1E3346"
        draw.rounded_rectangle((x, y, x + 395, y + 380), radius=22, fill=bg)
        thumb = exports[name].resize((330, 330), Image.Resampling.LANCZOS)
        board.paste(thumb, (x + 32, y + 13), thumb)
        draw.text((x + 23, y + 344), name.upper(), font=font, fill="#17304A" if row == 0 else "#FFFFFF")
    board.save(ROOT / "design" / "mentor" / "poses-preview.png")


def main() -> None:
    (ASSETS / "2.0x").mkdir(parents=True, exist_ok=True)
    exports = {}
    for name in POSES:
        image = make_export(name)
        image.save(ASSETS / "2.0x" / f"{name}.png", optimize=True)
        image.resize((512, 512), Image.Resampling.LANCZOS).save(ASSETS / f"{name}.png", optimize=True)
        exports[name] = image
    preview(exports)


if __name__ == "__main__":
    main()
