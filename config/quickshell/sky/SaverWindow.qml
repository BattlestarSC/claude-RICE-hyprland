// The screensaver for one screen: a full-screen Overlay-layer window showing the ASCII sky with
// the whole globe in view. Burn-in protection: every pixel moves. The scene pans along a slow
// Lissajous path (stars, nebula, Earth and Moon all drift), the Earth turns, the Moon orbits, and
// the clock wanders on its own path. Any key or click ends it (and hypridle's on-resume does too);
// it takes exclusive keyboard focus so that first key never reaches the window underneath.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    visible: Screensaver.active
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-screensaver"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.crust

    // Drift: one loop every saverDriftPeriod seconds, up to 18 % / 12 % of the screen.
    readonly property real phase: 2 * Math.PI * (SkyClock.seconds % Config.saverDriftPeriod) / Config.saverDriftPeriod
    readonly property point drift: Qt.point(width * 0.18 * Math.sin(phase), height * 0.12 * Math.sin(2 * phase + 0.7))

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => { Screensaver.active = false; event.accepted = true; }
        TapHandler { onTapped: Screensaver.active = false }

        AsciiSky {
            anchors.fill: parent
            cellWidth: Config.cellWidth
            cellHeight: Config.cellHeight
            // Canvas = the screen; panning the view (offset) moves everything, the globe included.
            offset: win.drift
            earthCenter: Qt.point(width * 0.5, height * 0.52)
            earthRadius: height * 0.30
            moonRadius: earthRadius * 0.27
            moonOrbit: earthRadius * 1.75

            earthAngle: SkyClock.earthAngle
            cloudAngle: SkyClock.cloudAngle
            moonAngle: SkyClock.moonAngle
            twinkle: SkyClock.twinkle

            shaderDir: Quickshell.shellPath("sky/shaders")
            landMask: Quickshell.shellPath("sky/land.png")
            atlas: Quickshell.dataPath("sky-atlas-" + Math.round(Config.cellWidth * win.screen.devicePixelRatio)
                                       + "x" + Math.round(Config.cellHeight * win.screen.devicePixelRatio) + ".png")
        }

        // Clock on its own, slower path (never parked in one place).
        Text {
            readonly property real p: 2 * Math.PI * (SkyClock.seconds % 1300) / 1300
            text: { SkyClock.seconds; return Qt.formatTime(new Date(), "HH:mm"); }   // re-evaluated every tick
            font.family: Theme.mono
            font.pixelSize: 64
            color: Theme.subtext
            opacity: 0.85
            x: (parent.width - width) / 2 + parent.width * 0.32 * Math.cos(p)
            y: parent.height * 0.12 + parent.height * 0.06 * Math.sin(3 * p)
        }
    }
}
