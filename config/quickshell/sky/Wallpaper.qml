// The ASCII sky as a wallpaper: one layer-shell window per screen on the Background layer.
// Pauses (stops re-rendering) while that monitor's workspace has a fullscreen window.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "rice-sky"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.crust

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property bool hidden: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.hasFullscreen : false

    // Canvas: this screen alone (mirror) or the bounding box of all screens (span).
    readonly property var screens: Quickshell.screens
    readonly property rect canvas: {
        if (Config.skyMode !== "span") return Qt.rect(0, 0, screen.width, screen.height);
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (const s of screens) {
            x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y);
            x1 = Math.max(x1, s.x + s.width); y1 = Math.max(y1, s.y + s.height);
        }
        return Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }
    readonly property bool span: Config.skyMode === "span" && screens.length > 1

    Component.onCompleted: SkyClock.views += 1
    Component.onDestruction: { SkyClock.views -= 1; if (hidden) SkyClock.pausedViews -= 1; }
    onHiddenChanged: SkyClock.pausedViews += hidden ? 1 : -1

    AsciiSky {
        anchors.fill: parent
        visible: !win.hidden
        cellWidth: Config.cellWidth
        cellHeight: Config.cellHeight

        offset: win.span ? Qt.point(win.screen.x - win.canvas.x, win.screen.y - win.canvas.y) : Qt.point(0, 0)
        // Span: the Earth rises on the left part of the sky, the Moon's wide orbit crosses screens.
        earthCenter: win.span ? Qt.point(win.canvas.width * 0.36, win.canvas.height)
                              : Qt.point(width * 0.5, height)
        earthRadius: win.canvas.height * 0.55
        moonRadius: earthRadius * 0.27
        moonOrbit: earthRadius * (win.span ? 2.4 : 1.6)

        earthAngle: SkyClock.earthAngle
        cloudAngle: SkyClock.cloudAngle
        moonAngle: SkyClock.moonAngle
        twinkle: SkyClock.twinkle

        shaderDir: Quickshell.shellPath("sky/shaders")
        landMask: Quickshell.shellPath("sky/land.png")
        // Glyph atlas rendered at this screen's exact physical cell size (bin/rice-sky-atlas).
        atlas: Quickshell.dataPath("sky-atlas-" + Math.round(Config.cellWidth * win.screen.devicePixelRatio)
                                   + "x" + Math.round(Config.cellHeight * win.screen.devicePixelRatio) + ".png")
    }
}
