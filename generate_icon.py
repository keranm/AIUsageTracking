#!/usr/bin/env python3
"""Generate ClaudePulse app icon — vertical bar chart style."""

from PIL import Image, ImageDraw, ImageFilter
import os, math

SIZES = [16, 32, 64, 128, 256, 512, 1024]

def draw_icon(size: int) -> Image.Image:
    scale = size / 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Background: rounded rect, dark charcoal
    r = int(size * 0.22)  # corner radius
    bg_color = (28, 28, 32, 255)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=bg_color)

    # Bar chart parameters
    num_bars = 4
    margin_x = int(size * 0.18)
    margin_bottom = int(size * 0.20)
    margin_top = int(size * 0.14)
    gap = int(size * 0.05)
    bar_area_w = size - 2 * margin_x
    bar_w = int((bar_area_w - gap * (num_bars - 1)) / num_bars)

    # Heights as fraction of available vertical space (left-to-right: varied)
    available_h = size - margin_top - margin_bottom
    heights_frac = [0.55, 1.0, 0.72, 0.38]

    # Colors: green → amber → orange → red
    colors = [
        (52, 199, 89),    # green
        (255, 159, 10),   # amber
        (255, 69, 58),    # red-orange
        (215, 45, 48),    # red
    ]

    bar_radius = max(2, int(bar_w * 0.28))

    for i, (frac, color) in enumerate(zip(heights_frac, colors)):
        bar_h = int(available_h * frac)
        x0 = margin_x + i * (bar_w + gap)
        x1 = x0 + bar_w
        y1 = size - margin_bottom
        y0 = y1 - bar_h

        # Slight glow behind each bar
        glow_color = (*color, 60)
        glow_expand = max(2, int(bar_w * 0.3))
        glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow_img)
        gd.rounded_rectangle(
            [x0 - glow_expand, y0 - glow_expand, x1 + glow_expand, y1 + glow_expand],
            radius=bar_radius + glow_expand,
            fill=glow_color
        )
        glow_img = glow_img.filter(ImageFilter.GaussianBlur(radius=max(1, int(bar_w * 0.4))))
        img = Image.alpha_composite(img, glow_img)
        d = ImageDraw.Draw(img)

        # Bar
        d.rounded_rectangle([x0, y0, x1, y1], radius=bar_radius, fill=(*color, 255))

        # Subtle highlight on top of bar (lighter strip)
        hi_h = max(2, int(bar_h * 0.12))
        hi_color = tuple(min(255, c + 60) for c in color) + (180,)
        hi_r = min(bar_radius, hi_h // 2)
        d.rounded_rectangle([x0, y0, x1, y0 + hi_h], radius=hi_r, fill=hi_color)

    return img


def make_iconset(out_dir: str):
    os.makedirs(out_dir, exist_ok=True)
    for size in SIZES:
        img = draw_icon(size)
        # 1x
        img.save(os.path.join(out_dir, f"icon_{size}x{size}.png"))
        # 2x (retina) — only meaningful for sizes <= 512 generating @2x
        if size <= 512:
            img2 = draw_icon(size * 2)
            img2.save(os.path.join(out_dir, f"icon_{size}x{size}@2x.png"))


if __name__ == "__main__":
    base = os.path.dirname(os.path.abspath(__file__))
    iconset = os.path.join(base, "ClaudePulse.iconset")
    make_iconset(iconset)
    print(f"Generated iconset at: {iconset}")
    print("Files:")
    for f in sorted(os.listdir(iconset)):
        print(f"  {f}")
