// Mock of config/quickshell/services/Audio.qml.
pragma Singleton
import QtQuick
QtObject {
    property var sink: null
    property real volume: 0.63
    property bool muted: false
    property var sinks: [
        { id: 51, name: "Speakers", description: "Schiit Modi+ (USB)", active: true },
        { id: 52, name: "Headphones", description: "USB DAC", active: false },
        { id: 53, name: "ProArt PA279", description: "DisplayPort audio", active: false },
    ]
    function setVolume(v) { volume = v; }
    function toggleMute() { muted = !muted; }
    function selectSink(id) { sinks = sinks.map(s => Object.assign({}, s, { active: s.id === id })); }
}
