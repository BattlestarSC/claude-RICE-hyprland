// Now playing, through MPRIS. Prefers a player that is currently playing.
//
// Interface (mirrored by tests/quickshell/qs/services/Media.qml):
//   available, playing, title, artist, position, length (seconds),
//   playPause(), next(), previous()
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    readonly property bool available: player !== null
    readonly property bool playing: player ? player.isPlaying : false
    readonly property string title: player ? player.trackTitle : ""
    readonly property string artist: player ? player.trackArtist : ""
    readonly property real position: player && player.positionSupported ? player.position : 0
    readonly property real length: player && player.lengthSupported ? player.length : 0

    function playPause() { if (player && player.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player && player.canGoNext) player.next(); }
    function previous() { if (player && player.canGoPrevious) player.previous(); }

    // MPRIS does not stream position updates; Quickshell's docs prescribe re-emitting once a second.
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: if (root.player) root.player.positionChanged()
    }
}
