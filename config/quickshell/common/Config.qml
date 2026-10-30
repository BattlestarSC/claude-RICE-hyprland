// Behavior settings for the shell (no colors: those are in the generated Theme.qml).
// Edit here; Quickshell reloads on save.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // ---- ASCII sky (wallpaper) ----
    // "mirror": every monitor shows the whole scene, in sync.
    // "span":   one sky across all monitors; the Moon's orbit crosses between them.
    readonly property string skyMode: "mirror"
    readonly property real skyFps: 10            // the scene moves slowly; 5-15 is plenty
    readonly property real cellWidth: 8          // logical px per character
    readonly property real cellHeight: 16
    // Periods in seconds. Kept as divisors of 86400 so the animation never jumps at midnight.
    readonly property real earthPeriod: 360      // one rotation every 6 minutes
    readonly property real cloudPeriod: 300      // clouds drift slightly faster than the ground
    readonly property real moonPeriod: 1800      // one orbit every 30 minutes
    readonly property real twinklePeriod: 9

    // ---- Bar ----
    readonly property int workspacesPerMonitor: 5  // left monitor 1-5, right 6-10 (Twin layout)
}
