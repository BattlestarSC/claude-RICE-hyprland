// One clock for every monitor's sky, so all screens show the same instant.
// Angles are computed in JavaScript doubles from wall-clock time and wrapped to [0, 2pi)
// before they reach the GPU, so shader float precision never degrades.
//
// The timer runs only while at least one monitor is animating (Wallpaper.qml votes through
// `animating`) and nothing has paused the sky over IPC:
//   qs ipc call sky pause     (hypridle on_lock_cmd: nothing to see behind the lock screen)
//   qs ipc call sky resume
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property int animating: 0                   // monitors currently animating
    property bool paused: false                 // set over IPC

    property real earthAngle: 0
    property real cloudAngle: 0
    property real moonAngle: 0
    property real twinkle: 0
    signal ticked()

    function angle(t, period) { return 2 * Math.PI * ((t % period) / period); }

    function tick() {
        const t = (Date.now() / 1000) % 86400;
        earthAngle = angle(t, Config.earthPeriod);
        cloudAngle = angle(t, Config.cloudPeriod);
        moonAngle = angle(t, Config.moonPeriod);
        twinkle = angle(t, Config.twinklePeriod);
        ticked();
    }

    Component.onCompleted: tick()               // angles for "still" mode and the first frame

    Timer {
        interval: 1000 / Config.skyFps
        repeat: true
        running: Config.skyMode === "animated" && root.animating > 0 && !root.paused
        onTriggered: root.tick()
    }

    IpcHandler {
        target: "sky"
        function pause(): void { root.paused = true; }
        function resume(): void { root.paused = false; }
    }
}
