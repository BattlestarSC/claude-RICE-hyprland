// Audio dropdown: volume, mute, output device selection, now playing.
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

PanelCard {
    icon: Audio.muted ? Icons.volumeOff : Icons.volume
    iconColor: Theme.audio
    title: "Audio"
    subtitle: Audio.sinks.filter(s => s.active).map(s => s.name)[0] || "no output"

    RowLayout {
        spacing: 10
        Layout.fillWidth: true
        Glyph { text: Audio.muted ? Icons.volumeOff : Icons.volume; color: Audio.muted ? Theme.overlay : Theme.text
                TapHandler { onTapped: Audio.toggleMute() } }
        Slider { value: Audio.volume; Layout.fillWidth: true; onMoved: v => Audio.setVolume(v) }
        Label { text: Fmt.pct(Audio.volume * 100); mono: true; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 44 }
    }

    Label { text: "OUTPUT"; color: Theme.overlay; font.pixelSize: Theme.smallSize; font.letterSpacing: 1.5 }
    Repeater {
        model: Audio.sinks
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: 10
            color: modelData.active ? Theme.selection : hover.hovered ? Theme.glassField : "transparent"
            border.width: modelData.active ? 1 : 0
            border.color: Theme.red
            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 10
                Glyph { text: Icons.forSink(modelData.name + " " + modelData.description)
                        color: modelData.active ? Theme.red : Theme.subtext }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Label { text: modelData.name; color: modelData.active ? Theme.bright : Theme.text; Layout.fillWidth: true }
                    Label { text: modelData.description; color: Theme.overlay; font.pixelSize: Theme.smallSize
                            Layout.fillWidth: true; visible: modelData.description !== modelData.name }
                }
                Glyph { visible: modelData.active; text: Icons.check; color: Theme.red }
            }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Audio.selectSink(modelData.id) }
        }
    }

    Label { visible: Media.available; text: "NOW PLAYING"; color: Theme.overlay; font.pixelSize: Theme.smallSize
            font.letterSpacing: 1.5 }
    ColumnLayout {
        visible: Media.available
        spacing: 6
        Layout.fillWidth: true
        Label { text: Media.title; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Label { text: Media.artist; color: Theme.subtext; Layout.fillWidth: true }
        RowLayout {
            spacing: 8
            Layout.fillWidth: true
            Label { text: Fmt.duration(Media.position); mono: true; font.pixelSize: Theme.smallSize; color: Theme.subtext }
            Meter { value: Media.length > 0 ? 100 * Media.position / Media.length : 0; fill: Theme.purple
                    Layout.fillWidth: true; implicitHeight: 4 }
            Label { text: Fmt.duration(Media.length); mono: true; font.pixelSize: Theme.smallSize; color: Theme.subtext }
        }
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 22
            Glyph { text: Icons.previous; TapHandler { onTapped: Media.previous() } }
            Glyph { text: Media.playing ? Icons.pause : Icons.play; color: Theme.bright; font.pixelSize: Theme.fontSize + 8
                    TapHandler { onTapped: Media.playPause() } }
            Glyph { text: Icons.next; TapHandler { onTapped: Media.next() } }
        }
    }
}
