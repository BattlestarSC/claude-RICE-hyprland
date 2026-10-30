#!/usr/bin/env python3
"""Render ASCII sky frames through real Qt Quick (PySide6), outside any compositor. Dev-only.

    python tests/sky/render.py OUTDIR [--size 1920x1080] [--dpr 1.0] [--frames 24] [--span]

Needs PySide6 with the Addons wheel (for qsb) and an OpenGL driver (Mesa llvmpipe is fine;
timings are then CPU-rendered and NOT representative of the GPU). Steps: render the shader
templates, compile them with qsb exactly as the installer will, build the glyph atlas with
bin/rice-sky-atlas, then load AsciiSky.qml via tests/sky/Harness.qml and grab frames while
advancing the angles the way SkyClock does.
"""

from __future__ import annotations

import argparse
import math
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def build_assets(out: Path, cell_px: tuple[int, int]) -> Path:
    assets = out / "assets"
    assets.mkdir(parents=True, exist_ok=True)
    subprocess.run([sys.executable, str(REPO / "tools/render_theme.py"), str(REPO / "colors/quasar.toml")],
                   check=True, stdout=subprocess.DEVNULL)
    qsb = shutil.which("pyside6-qsb") or str(Path(sys.executable).parent / "pyside6-qsb")
    for name in ("scene", "glyph"):
        subprocess.run([qsb, "--glsl", "100es,120,150", "--hlsl", "50", "--msl", "12",
                        "-o", str(assets / f"{name}.frag.qsb"),
                        str(REPO / f"themes/quasar/quickshell/sky/{name}.frag")], check=True)
    subprocess.run([str(REPO / "bin/rice-sky-atlas"), str(cell_px[0]), str(cell_px[1]), str(assets / "atlas.png")],
                   check=True)
    shutil.copy(REPO / "assets/earth/land-1024x512.png", assets / "land.png")
    return assets


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("out", type=Path)
    ap.add_argument("--size", default="1920x1080")
    ap.add_argument("--dpr", type=float, default=1.0)
    ap.add_argument("--cell", default="8x16", help="logical cell size")
    ap.add_argument("--frames", type=int, default=24)
    ap.add_argument("--span", action="store_true", help="render the right half of a two-monitor canvas")
    a = ap.parse_args()

    w, h = (int(v) for v in a.size.split("x"))
    cw, ch = (int(v) for v in a.cell.split("x"))
    a.out.mkdir(parents=True, exist_ok=True)
    assets = build_assets(a.out, (round(cw * a.dpr), round(ch * a.dpr)))

    os.environ.setdefault("QSG_RHI_BACKEND", "opengl")
    os.environ["QT_SCALE_FACTOR"] = str(a.dpr)
    from PySide6.QtCore import QObject, QPointF, QUrl
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQuick import QQuickView

    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(int(w / a.dpr), int(h / a.dpr))
    view.setSource(QUrl.fromLocalFile(str(REPO / "tests/sky/Harness.qml")))
    if view.status() != QQuickView.Ready:
        for err in view.errors():
            print("QML error:", err.toString())
        return 1
    sky = view.rootObject().findChild(QObject, "sky")
    lw, lh = w / a.dpr, h / a.dpr
    sky.setProperty("cellWidth", cw)
    sky.setProperty("cellHeight", ch)
    sky.setProperty("shaderDir", QUrl.fromLocalFile(str(assets)))
    sky.setProperty("landMask", QUrl.fromLocalFile(str(assets / "land.png")))
    sky.setProperty("atlas", QUrl.fromLocalFile(str(assets / "atlas.png")))
    # Mirror mode uses AsciiSky's defaults. Span mode: the Earth sits on the left monitor and
    # the Moon's wider orbit carries it across onto the right one (this renders the right one).
    if a.span:
        sky.setProperty("offset", QPointF(lw, 0))
        sky.setProperty("earthCenter", QPointF(lw * 0.72, lh * 1.0))
        sky.setProperty("earthRadius", lh * 0.55)
        sky.setProperty("moonRadius", lh * 0.55 * 0.27)
        sky.setProperty("moonOrbit", lh * 0.55 * 2.4)
    view.show()

    times = []
    for i in range(a.frames):
        t = i / max(1, a.frames)               # one full Earth turn across the sequence
        # Earth: one full turn over the sequence. Moon: across the visible (near) half of its orbit.
        angles = {"earthAngle": 2 * math.pi * t, "moonAngle": math.pi * (0.05 + 0.9 * t),
                  "cloudAngle": 2 * math.pi * t * 1.3, "twinkle": 2 * math.pi * t * 3}
        for prop, value in angles.items():
            sky.setProperty(prop, value % (2 * math.pi))
        t0 = time.perf_counter()
        img = view.grabWindow()                # forces a synchronous render
        times.append(time.perf_counter() - t0)
        img.save(str(a.out / f"frame-{i:03d}.png"))
    times.sort()
    print(f"{a.frames} frames {w}x{h} (dpr {a.dpr}, cells {math.ceil(lw / cw)}x{math.ceil(lh / ch)}): "
          f"median {times[len(times) // 2] * 1000:.1f} ms/frame on this renderer")
    return 0


if __name__ == "__main__":
    sys.exit(main())
