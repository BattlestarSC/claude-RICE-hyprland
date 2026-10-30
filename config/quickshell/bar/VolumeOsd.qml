// On-screen volume card: speaker icon, level bar, percentage. Shown by OsdWindow.qml for a moment
// whenever the default output's volume or mute changes (keys, bar, pavucontrol, other apps).
// Plain QtQuick (no Quickshell types) so tests/quickshell/render.py can draw it.
import QtQuick
import qs.common

Rectangle {
    id: osd
    property real volume: 0
    property bool muted: false
    property string device: ""

    implicitWidth: 320
    implicitHeight: 64
    radius: Theme.panelRadius
    color: Theme.glass
    border.color: Theme.glassEdge
    border.width: 1

    Glyph {
        id: icon
        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
        text: osd.muted || osd.volume <= 0 ? Icons.volumeOff : Icons.volume
        color: osd.muted ? Theme.overlay : Theme.red
        font.pixelSize: Theme.fontSize + 9
    }
    Column {
        anchors { left: icon.right; leftMargin: 14; right: pct.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 6
        Rectangle {
            width: parent.width; height: 8; radius: 4
            color: Theme.track
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, osd.volume)); height: parent.height; radius: 4
                opacity: osd.muted ? 0.35 : 1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.red }
                    GradientStop { position: 1; color: Theme.purple } }
            }
        }
        Label {
            width: parent.width
            text: osd.muted ? "muted" + (osd.device ? " · " + osd.device : "") : osd.device
            color: Theme.overlay
            font.pixelSize: Theme.smallSize
            elide: Text.ElideRight
            visible: text.length > 0
        }
    }
    Label {
        id: pct
        anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
        width: 48
        horizontalAlignment: Text.AlignRight
        mono: true
        text: Fmt.pct(osd.volume * 100)
        color: osd.muted ? Theme.overlay : Theme.text
    }
}
