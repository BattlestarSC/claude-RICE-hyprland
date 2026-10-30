// Volume OSD window: bottom center of the primary monitor, on the Overlay layer (above fullscreen
// apps), never takes keyboard focus or clicks. Appears on any change of the default output's
// volume or mute and hides 1.5 s after the last one. Changes in the first 2 s after start (or
// right after the default output switches) are the initial values arriving, not the user: ignored.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

PanelWindow {
    id: win

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true }
    margins { bottom: 96 }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    color: "transparent"
    mask: Region {}            // click-through
    visible: shown

    property bool shown: false
    property bool armed: false

    function poke() {
        if (!armed) return;
        shown = true;
        hide.restart();
    }

    Connections {
        target: Audio
        function onVolumeChanged() { win.poke(); }
        function onMutedChanged() { win.poke(); }
        function onSinkChanged() { win.armed = false; arm.restart(); }
    }
    Timer { id: arm; interval: 2000; running: true; onTriggered: win.armed = true }
    Timer { id: hide; interval: 1500; onTriggered: win.shown = false }

    VolumeOsd {
        id: card
        volume: Audio.volume
        muted: Audio.muted
        device: Audio.sinks.filter(s => s.active).map(s => s.name)[0] || ""
    }
}
