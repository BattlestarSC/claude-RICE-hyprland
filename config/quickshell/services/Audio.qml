// Output volume, mute and output-device selection through PipeWire.
//
// Interface (mirrored by tests/quickshell/qs/services/Audio.qml):
//   volume (0..1), muted, sinks[]: { id, name, description, active },
//   setVolume(v), toggleMute(), selectSink(id)
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property var sinks: Pipewire.nodes.values
        .filter(n => n.isSink && !n.isStream && n.audio)
        .map(n => ({
            id: n.id,
            name: n.nickname || n.description || n.name,
            description: n.description || n.name,
            active: n === Pipewire.defaultAudioSink,
        }))

    function setVolume(v) {
        if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
    }
    // Writing preferredDefaultAudioSink makes PipeWire switch the default output.
    function selectSink(id) {
        const n = Pipewire.nodes.values.find(n => n.id === id);
        if (n) Pipewire.preferredDefaultAudioSink = n;
    }

    // Nodes only report live audio properties while bound by a tracker.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
}
