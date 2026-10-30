// Behavior settings for the shell (no colors: those are in the generated Theme.qml).
//
// Per-user choices live in ~/.config/rice/settings.json. The installer writes that file once
// from its questions and never overwrites it; edit it any time, the shell picks changes up live.
// Missing keys fall back to the defaults below. Example:
//   { "skyMode": "animated", "skyLayout": "mirror", "skyFps": 4,
//     "skyAnimateWithWindows": false, "skyImage": "", "saverFps": 8 }
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---- Wallpaper ----
    // "animated": live ASCII Earth and Moon (GPU shaders, see docs/knowledge-base/bar.md)
    // "still":    the same ASCII scene rendered once at startup, then never redrawn (zero cost)
    // "image":    a picture of your choice (skyImage), e.g. a NASA photo of the Earth
    readonly property string skyMode: ["animated", "still", "image"].includes(settings.skyMode) ? settings.skyMode : "animated"
    // "mirror": every monitor shows the whole scene, in sync.
    // "span":   one sky across all monitors; the Moon's orbit crosses between them.
    readonly property string skyLayout: settings.skyLayout === "span" ? "span" : "mirror"
    // The Earth's equator moves ~1.7 character cells per second at 4K, so a few frames per second
    // already show every step; higher rates mostly redraw identical characters.
    readonly property real skyFps: Math.max(1, Math.min(30, settings.skyFps))
    // false: animate only while this monitor's workspace has no windows (tiled windows cover the
    // sky anyway; the frame freezes and costs nothing). true: animate behind windows too.
    readonly property bool skyAnimateWithWindows: settings.skyAnimateWithWindows
    readonly property string skyImage: settings.skyImage

    readonly property real cellWidth: 8          // logical px per character
    readonly property real cellHeight: 16
    // Periods in seconds. Kept as divisors of 86400 so the animation never jumps at midnight.
    readonly property real earthPeriod: 360      // one rotation every 6 minutes
    readonly property real cloudPeriod: 300      // clouds drift slightly faster than the ground
    readonly property real moonPeriod: 1800      // one orbit every 30 minutes
    readonly property real twinklePeriod: 9

    // ---- Screensaver (sky/SaverWindow.qml; hypridle starts it) ----
    // Smoother than the wallpaper because the whole scene pans (anti burn-in) and nothing covers it.
    readonly property real saverFps: Math.max(1, Math.min(30, settings.saverFps))
    readonly property real saverDriftPeriod: 900  // seconds for one full drift loop of the scene

    // ---- Bar ----
    readonly property int workspacesPerMonitor: 5  // left monitor 1-5, right 6-10 (Twin layout)

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/rice/settings.json"
        watchChanges: true
        onFileChanged: reload()
        printErrors: false                       // a missing file just means "all defaults"

        adapter: JsonAdapter {
            id: settings
            property string skyMode: "animated"
            property string skyLayout: "mirror"
            property real skyFps: 4
            property bool skyAnimateWithWindows: false
            property string skyImage: ""
            property real saverFps: 8
        }
    }
}
