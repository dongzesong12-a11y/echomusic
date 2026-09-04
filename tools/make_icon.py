"""生成 EchoMusic 的 AppIcon（纯标准库，无需 Pillow）。

用法：
    python tools/make_icon.py

输出到 EchoMusic/Resources/Assets.xcassets/AppIcon.appiconset/

注意：多个条目可能映射到同一像素尺寸（如 40@3x 与 60@2x 都是 120px）。
脚本只算一次像素，但每个条目都会写出自己的文件名，
保证 Contents.json 里引用的每一张图都真实存在（否则 Xcode 编 asset catalog 会失败）。
"""
from __future__ import annotations

import math
import os
import struct
import zlib

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "EchoMusic",
    "Resources",
    "Assets.xcassets",
    "AppIcon.appiconset",
)

# 渐变三档：深紫 -> 品红 -> 青
STOPS = (
    (0.00, (109, 40, 217)),   # #6D28D9
    (0.55, (219, 39, 119)),   # #DB2777
    (1.00, (34, 211, 238)),   # #22D3EE
)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def gradient(t: float) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    for i in range(len(STOPS) - 1):
        t0, c0 = STOPS[i]
        t1, c1 = STOPS[i + 1]
        if t0 <= t <= t1:
            k = 0.0 if t1 == t0 else (t - t0) / (t1 - t0)
            # smoothstep，让过渡更顺
            k = k * k * (3.0 - 2.0 * k)
            return (
                int(round(lerp(c0[0], c1[0], k))),
                int(round(lerp(c0[1], c1[1], k))),
                int(round(lerp(c0[2], c1[2], k))),
            )
    return STOPS[-1][1]


def pixel(x: int, y: int, w: int, h: int) -> tuple[int, int, int]:
    s = float(w)

    # 对角线渐变
    t = (x / s) * 0.45 + (y / s) * 0.55
    r, g, b = gradient(t)

    # 左下角为圆心的三道声波弧
    cx, cy = -0.12 * s, 1.12 * s
    d = math.hypot(x - cx, y - cy)

    arcs = (
        (0.62 * s, 0.052 * s, 0.95),
        (0.86 * s, 0.040 * s, 0.55),
        (1.08 * s, 0.030 * s, 0.30),
    )
    for radius, width, alpha in arcs:
        delta = abs(d - radius)
        if delta <= width * 0.5:
            # 边缘做 1px 羽化
            edge = 1.0 - (delta / (width * 0.5))
            a = alpha * min(1.0, edge * 3.0)
            r = int(round(lerp(r, 255, a)))
            g = int(round(lerp(g, 255, a)))
            b = int(round(lerp(b, 255, a)))

    # 底部压暗，图标有重量感
    vign = 1.0 - 0.28 * max(0.0, (y / s - 0.55) / 0.45) ** 2
    return (
        max(0, min(255, int(r * vign))),
        max(0, min(255, int(g * vign))),
        max(0, min(255, int(b * vign))),
    )


def make_pixels(w: int, h: int) -> bytes:
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter type 0
        row = bytearray()
        for x in range(w):
            r, g, b = pixel(x, y, w, h)
            row += bytes((r, g, b))
        raw += row
    return bytes(raw)


def write_png(path: str, w: int, h: int) -> None:
    raw = make_pixels(w, h)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)  # 8bit RGB，不带 alpha
    blob = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    with open(path, "wb") as f:
        f.write(blob)


# (idiom, size_pt, scale) -> 文件名, 像素边长
ICONS = [
    ("iphone", "20x20", "2x", "icon-20@2x.png", 40),
    ("iphone", "20x20", "3x", "icon-20@3x.png", 60),
    ("iphone", "29x29", "2x", "icon-29@2x.png", 58),
    ("iphone", "29x29", "3x", "icon-29@3x.png", 87),
    ("iphone", "40x40", "2x", "icon-40@2x.png", 80),
    ("iphone", "40x40", "3x", "icon-40@3x.png", 120),
    ("iphone", "60x60", "2x", "icon-60@2x.png", 120),
    ("iphone", "60x60", "3x", "icon-60@3x.png", 180),
    ("ipad", "20x20", "1x", "icon-20.png", 20),
    ("ipad", "20x20", "2x", "icon-20@2x.png", 40),
    ("ipad", "29x29", "1x", "icon-29.png", 29),
    ("ipad", "29x29", "2x", "icon-29@2x.png", 58),
    ("ipad", "40x40", "1x", "icon-40.png", 40),
    ("ipad", "40x40", "2x", "icon-40@2x.png", 80),
    ("ipad", "76x76", "1x", "icon-76.png", 76),
    ("ipad", "76x76", "2x", "icon-76@2x.png", 152),
    ("ipad", "83.5x83.5", "2x", "icon-83.5@2x.png", 167),
    ("ios-marketing", "1024x1024", "1x", "icon-1024.png", 1024),
]


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    bufs: dict[int, bytes] = {}
    images = []
    for idiom, size, scale, filename, px in ICONS:
        if px not in bufs:
            bufs[px] = make_pixels(px, px)
        write_png(os.path.join(OUT_DIR, filename), px, px)
        print(f"  生成 {filename} ({px}x{px})")
        images.append((idiom, size, scale, filename))

    lines = ["{", '  "images": [']
    entries = []
    for idiom, size, scale, filename in images:
        entries.append(
            "    {\n"
            f'      "idiom": "{idiom}",\n'
            f'      "size": "{size}",\n'
            f'      "scale": "{scale}",\n'
            f'      "filename": "{filename}"\n'
            "    }"
        )
    lines.append(",\n".join(entries))
    lines.append("  ],")
    lines.append('  "info": {')
    lines.append('    "version": 1,')
    lines.append('    "author": "xcode"')
    lines.append("  }")
    lines.append("}")

    contents = "\n".join(lines) + "\n"
    with open(os.path.join(OUT_DIR, "Contents.json"), "w", encoding="utf-8") as f:
        f.write(contents)

    print(f"完成，共 {len(images)} 张图 -> {OUT_DIR}")


if __name__ == "__main__":
    main()
