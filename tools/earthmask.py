#!/usr/bin/env python3
"""Rasterize Natural Earth land polygons into an equirectangular land mask (grayscale PNG).

Usage:
    curl -O https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_50m_land.geojson
    tools/earthmask.py ne_50m_land.geojson 1024 512 > assets/earth/land-1024x512.png

Natural Earth is public domain. The mask is the only "real Earth" input to the ASCII wallpaper
shader; colors, clouds, lighting and rotation are computed on the GPU. Dev-only, run once.
Pixel (x, y) covers longitude -180 + 360 * (x + 0.5) / W and latitude 90 - 180 * (y + 0.5) / H.
"""

from __future__ import annotations

import json
import struct
import sys
import zlib


def rings(geojson: dict):
    for feat in geojson["features"]:
        g = feat["geometry"]
        polys = [g["coordinates"]] if g["type"] == "Polygon" else g["coordinates"]
        for poly in polys:
            yield poly  # [exterior, hole, hole, ...]


def rasterize(geojson: dict, w: int, h: int) -> bytearray:
    img = bytearray(w * h)
    for poly in rings(geojson):
        edges = []
        ymin, ymax = 90.0, -90.0
        for ring in poly:
            for (x0, y0), (x1, y1) in zip(ring, ring[1:]):
                if y0 != y1:
                    edges.append((x0, y0, x1, y1))
                ymin, ymax = min(ymin, y0, y1), max(ymax, y0, y1)
        r0 = max(0, int((90 - ymax) / 180 * h) - 1)
        r1 = min(h - 1, int((90 - ymin) / 180 * h) + 1)
        for row in range(r0, r1 + 1):
            lat = 90 - 180 * (row + 0.5) / h
            xs = sorted(x0 + (lat - y0) * (x1 - x0) / (y1 - y0)
                        for x0, y0, x1, y1 in edges if (y0 <= lat < y1) or (y1 <= lat < y0))
            for a, b in zip(xs[::2], xs[1::2]):          # even-odd fill: holes cancel out
                c0 = max(0, int((a + 180) / 360 * w + 0.5))
                c1 = min(w, int((b + 180) / 360 * w + 0.5))
                base = row * w
                for col in range(c0, c1):
                    img[base + col] ^= 0xFF
    return img


def png_gray(pixels: bytearray, w: int, h: int) -> bytes:
    raw = b"".join(b"\x00" + bytes(pixels[r * w:(r + 1) * w]) for r in range(h))

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 0, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2
    w, h = int(argv[2]), int(argv[3])
    with open(argv[1]) as fh:
        mask = rasterize(json.load(fh), w, h)
    sys.stdout.buffer.write(png_gray(mask, w, h))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
