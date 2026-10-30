// One clock for every monitor's sky, so all screens show the same instant.
// Angles are computed in JavaScript doubles from wall-clock time and wrapped to [0, 2pi)
// before they reach the GPU, so shader float precision never degrades.
pragma Singleton
import QtQuick
import Quickshell
import qs.common

Singleton {
    id: root

    property bool running: true                 // Wallpaper windows vote via the pause count
    property int pausedViews: 0
    property int views: 0

    property real earthAngle: 0
    property real cloudAngle: 0
    property real moonAngle: 0
    property real twinkle: 0

    function angle(t, period) { return 2 * Math.PI * ((t % period) / period); }

    function tick() {
        const t = (Date.now() / 1000) % 86400;
        earthAngle = angle(t, Config.earthPeriod);
        cloudAngle = angle(t, Config.cloudPeriod);
        moonAngle = angle(t, Config.moonPeriod);
        twinkle = angle(t, Config.twinklePeriod);
    }

    // Stops entirely when every monitor's sky is hidden (fullscreen apps on all of them).
    Timer {
        interval: 1000 / Config.skyFps
        repeat: true
        triggeredOnStart: true
        running: root.running && root.pausedViews < root.views
        onTriggered: root.tick()
    }
}
