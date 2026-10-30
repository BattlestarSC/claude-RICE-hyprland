// The frosted dropdown card: header (icon, title, subtitle, optional header control) + content.
import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: card
    property string icon: ""
    property color iconColor: Theme.red
    property string title: ""
    property string subtitle: ""
    default property alias content: body.data
    property alias headerExtra: extra.data

    implicitWidth: Theme.panelWidth
    implicitHeight: col.implicitHeight + 32
    radius: Theme.panelRadius
    color: Theme.glass
    border.width: 1
    border.color: Theme.glassEdge

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 16 }
        spacing: 12
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            Glyph { text: card.icon; color: card.iconColor; font.pixelSize: Theme.fontSize + 6 }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Label { text: card.title; font.weight: Font.DemiBold; color: Theme.bright }
                Label { text: card.subtitle; color: Theme.overlay; font.pixelSize: Theme.smallSize; visible: text !== ""
                        Layout.fillWidth: true }
            }
            Row { id: extra; spacing: 8 }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.glassEdge }
        ColumnLayout { id: body; spacing: 10; Layout.fillWidth: true }
    }
}
