#!/usr/bin/env python3
"""Render the Quickshell bar components (real QML, mock services) through Qt Quick. Dev-only.

    python tests/quickshell/render.py OUT.png [--size 2560x1440] [--dpr 1.5] [--background sky.png]

Builds a temporary import tree so the real files resolve their `import qs.*` statements:
    qs/common   <- config/quickshell/common + generated Theme.qml
    qs/bar      <- config/quickshell/bar
    qs/services <- tests/quickshell/mocks       (same interfaces as config/quickshell/services)
    Quickshell  <- tests/quickshell/stubs/Quickshell (Singleton = QtObject)
Fails (exit 1) on any QML error or warning, so a broken binding cannot pass silently.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent


def module(dst: Path, name: str, sources: list[Path]) -> None:
    dst.mkdir(parents=True)
    lines = [f"module {name}"]
    for src in sources:
        for f in sorted(src.glob("*.qml")):
            shutil.copy(f, dst / f.name)
            kind = "singleton " if "pragma Singleton" in f.read_text() else ""
            lines.append(f"{kind}{f.stem} 1.0 {f.name}")
    (dst / "qmldir").write_text("\n".join(lines) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("out", type=Path)
    ap.add_argument("--size", default="2560x1440", help="logical size")
    ap.add_argument("--dpr", type=float, default=1.5)
    ap.add_argument("--background", type=Path)
    a = ap.parse_args()

    tmp = Path(tempfile.mkdtemp())
    module(tmp / "qs/common", "qs.common", [REPO / "config/quickshell/common", REPO / "themes/quasar/quickshell/common"])
    module(tmp / "qs/bar", "qs.bar", [REPO / "config/quickshell/bar"])
    module(tmp / "qs/services", "qs.services", [HERE / "mocks"])
    shutil.copytree(HERE / "stubs/Quickshell", tmp / "Quickshell")
    shutil.copy(HERE / "BarTest.qml", tmp / "BarTest.qml")

    os.environ.setdefault("QSG_RHI_BACKEND", "opengl")
    # Single-threaded render loop: with the threaded loop, a QML warning raised on the render
    # thread re-enters the Python message handler while grabWindow() holds the GIL (deadlock).
    os.environ["QSG_RENDER_LOOP"] = "basic"
    os.environ["QT_SCALE_FACTOR"] = str(a.dpr)
    from PySide6.QtCore import QtMsgType, QUrl, qInstallMessageHandler
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQuick import QQuickView

    problems: list[str] = []

    def on_message(kind, ctx, msg):
        if kind in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg) and "qml" in (ctx.file or "qml").lower() or ".qml" in msg:
            problems.append(msg)
        print(msg, file=sys.stderr)

    qInstallMessageHandler(on_message)
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.engine().addImportPath(str(tmp))
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    w, h = (int(v) for v in a.size.split("x"))
    view.resize(w, h)
    view.setSource(QUrl.fromLocalFile(str(tmp / "BarTest.qml")))
    if view.status() != QQuickView.Ready:
        for e in view.errors():
            print("QML error:", e.toString())
        return 1
    if a.background:
        view.rootObject().setProperty("background", QUrl.fromLocalFile(str(a.background.resolve())))
    view.show()
    for _ in range(20):
        app.processEvents()
    view.grabWindow().save(str(a.out))
    shutil.rmtree(tmp)
    if problems:
        print(f"FAIL: {len(problems)} QML warning(s)")
        return 1
    print(f"OK: rendered {a.out} ({w}x{h} logical, dpr {a.dpr})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
