// The wallpaper: one layer-shell window per screen on the Background layer, showing the ASCII
// sky (animated or still) or a picture, per Config.skyMode.
//
// Cost control. A frame is only rendered when something changes, so a monitor whose sky is not
// animating costs nothing after its last frame. A monitor animates only when all of these hold:
//   - skyMode is "animated" and the sky is not paused over IPC (lock screen)
//   - its active workspace has no fullscreen window (then the sky is hidden entirely)
//   - its active workspace has no windows at all, unless skyAnimateWithWindows is set
// Otherwise it keeps its last frame (frozen) while other monitors may keep animating.
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
    readonly property var workspace: monitor ? monitor.activeWorkspace : null
    readonly property bool hidden: workspace ? workspace.hasFullscreen : false
    readonly property bool covered: workspace ? workspace.toplevels.values.length > 0 : false
    readonly property bool animating: Config.skyMode === "animated" && !hidden
                                      && (Config.skyAnimateWithWindows || !covered)

    // Vote in SkyClock: its timer runs while any monitor animates.
    property bool counted: false
    function vote() {
        if (animating === counted) return;
        SkyClock.animating += animating ? 1 : -1;
        counted = animating;
    }
    onAnimatingChanged: vote()
    Component.onCompleted: vote()
    Component.onDestruction: if (counted) SkyClock.animating -= 1

    // Canvas: this screen alone (mirror) or the bounding box of all screens (span).
    readonly property var screens: Quickshell.screens
    readonly property rect canvas: {
        if (Config.skyLayout !== "span") return Qt.rect(0, 0, screen.width, screen.height);
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (const s of screens) {
            x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y);
            x1 = Math.max(x1, s.x + s.width); y1 = Math.max(y1, s.y + s.height);
        }
        return Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }
    readonly property bool span: Config.skyLayout === "span" && screens.length > 1

    Loader {
        anchors.fill: parent
        visible: !win.hidden
        sourceComponent: Config.skyMode === "image" ? picture : ascii
    }

    Component {
        id: picture
        Image {
            source: Config.skyImage ? "file://" + Config.skyImage : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            // Decode at the output's pixel size, not the file's (a 8K photo would cost ~130 MB).
            sourceSize: Qt.size(win.width * win.screen.devicePixelRatio, win.height * win.screen.devicePixelRatio)
        }
    }

    Component {
        id: ascii
        AsciiSky {
            id: sky
            cellWidth: Config.cellWidth
            cellHeight: Config.cellHeight

            offset: win.span ? Qt.point(win.screen.x - win.canvas.x, win.screen.y - win.canvas.y) : Qt.point(0, 0)
            // Span: the Earth rises on the left part of the sky, the Moon's wide orbit crosses screens.
            earthCenter: win.span ? Qt.point(win.canvas.width * 0.36, win.canvas.height)
                                  : Qt.point(width * 0.5, height)
            earthRadius: win.canvas.height * 0.55
            moonRadius: earthRadius * 0.27
            moonOrbit: earthRadius * (win.span ? 2.4 : 1.6)

            // Angles are copied, not bound: a frozen monitor must keep its last frame while
            // SkyClock keeps ticking for the others.
            function sync() {
                earthAngle = SkyClock.earthAngle;
                cloudAngle = SkyClock.cloudAngle;
                moonAngle = SkyClock.moonAngle;
                twinkle = SkyClock.twinkle;
            }
            Component.onCompleted: sync()
            Connections {
                target: SkyClock
                function onTicked() { if (win.animating) sky.sync(); }
            }

            shaderDir: Quickshell.shellPath("sky/shaders")
            landMask: Quickshell.shellPath("sky/land.png")
            // Glyph atlas rendered at this screen's exact physical cell size (bin/rice-sky-atlas).
            atlas: Quickshell.dataPath("sky-atlas-" + Math.round(Config.cellWidth * win.screen.devicePixelRatio)
                                       + "x" + Math.round(Config.cellHeight * win.screen.devicePixelRatio) + ".png")
        }
    }
}
