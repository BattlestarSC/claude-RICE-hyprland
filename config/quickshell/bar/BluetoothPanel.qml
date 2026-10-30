// Bluetooth dropdown: adapter power, scan, devices (click to connect / disconnect / pair).
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

PanelCard {
    icon: !Bluetooth.enabled ? Icons.bluetoothOff : Bluetooth.connectedCount > 0 ? Icons.bluetoothConnected : Icons.bluetooth
    iconColor: Bluetooth.enabled ? Theme.bt : Theme.overlay
    title: "Bluetooth"
    subtitle: !Bluetooth.available ? "no adapter" : !Bluetooth.enabled ? "off"
              : Bluetooth.connectedCount + " connected" + (Bluetooth.discovering ? " · scanning" : "")
    headerExtra: [
        Toggle { checked: Bluetooth.enabled; onToggled: on => Bluetooth.setEnabled(on) }
    ]

    Repeater {
        model: Bluetooth.enabled ? Bluetooth.devices : []
        Rectangle {
            id: row
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 10
            color: modelData.connected ? Theme.selection : hover.hovered ? Theme.glassField : "transparent"
            border.width: modelData.connected ? 1 : 0
            border.color: Theme.red
            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 10
                Glyph { text: Icons.forBluetooth(modelData.icon); color: modelData.connected ? Theme.bt : Theme.subtext }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Label { text: modelData.name; color: modelData.connected ? Theme.bright : Theme.text; Layout.fillWidth: true }
                    Label { text: modelData.pairing ? "pairing…" : modelData.connected ? "connected" : modelData.paired ? "paired" : "new device"
                            color: Theme.overlay; font.pixelSize: Theme.smallSize }
                }
                Label { visible: modelData.battery >= 0; text: Math.round(modelData.battery * 100) + "%"; mono: true
                        color: modelData.battery < 0.2 ? Theme.red : Theme.subtext }
            }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Bluetooth.toggle(modelData.address) }
        }
    }
    Label {
        visible: Bluetooth.enabled && Bluetooth.devices.length === 0
        text: "No paired devices"; color: Theme.overlay
    }
    Rectangle {                                     // scan button
        visible: Bluetooth.enabled
        Layout.fillWidth: true
        implicitHeight: 32
        radius: 16
        color: Bluetooth.discovering ? Theme.selection : Theme.glassField
        border.width: 1
        border.color: Bluetooth.discovering ? Theme.red : Theme.glassEdge
        Label { anchors.centerIn: parent; text: Bluetooth.discovering ? "Stop scanning" : "Scan for devices" }
        TapHandler { onTapped: Bluetooth.scan(!Bluetooth.discovering) }
    }
}
