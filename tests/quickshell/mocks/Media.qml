// Mock of config/quickshell/services/Media.qml.
pragma Singleton
import QtQuick
QtObject {
    property bool available: true
    property bool playing: true
    property string title: "Track title"
    property string artist: "Artist"
    property real position: 86
    property real length: 220
    function playPause() { playing = !playing; }
    function next() {}
    function previous() {}
}
