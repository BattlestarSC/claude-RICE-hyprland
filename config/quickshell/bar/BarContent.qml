// Orbit Glass: the bar's contents, a row of frosted pills. Pure Qt Quick so it renders in tests;
// Bar.qml supplies the window, the workspace data and the dropdown popup.
//
//   left:   workspaces · window title
//   center: clock
//   right:  CPU/memory/load · drives · network · Bluetooth · volume · media · notifications · power
import QtQuick
import qs.common
import qs.services

Item {
    id: root

    property var workspaces: []                  // [{ id, active, occupied }]
    property string title: ""
    property bool primary: true                  // full telemetry on the primary screen only
    property string openPanel: ""                // name of the open dropdown, for highlighting
    property date now: new Date()
    signal workspaceClicked(int id)
    signal panelRequested(string name, Item anchor)
    signal powerRequested()

    implicitHeight: Theme.barHeight

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // ---- left ----
    Row {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: Theme.gap / 2

        Pill {
            interactive: false
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: root.workspaces
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: modelData.active ? 22 : 8
                        height: 8
                        radius: 4
                        color: modelData.active ? Theme.red : modelData.occupied ? Theme.subtext : Theme.surface2
                        gradient: modelData.active ? activeGrad : null
                        Behavior on width { NumberAnimation { duration: 160 } }
                        TapHandler { onTapped: root.workspaceClicked(modelData.id) }
                    }
                }
            }
        }
        Pill {
            interactive: false
            visible: root.title !== ""
            Label { text: root.title; width: Math.min(implicitWidth, 360); color: Theme.subtext
                    anchors.verticalCenter: parent.verticalCenter }
        }
    }
    Gradient { id: activeGrad; orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Theme.red }
        GradientStop { position: 1; color: Theme.purple } }

    // ---- center ----
    Pill {
        anchors.centerIn: parent
        interactive: false
        Label { text: Qt.formatTime(root.now, "HH:mm"); font.weight: Font.DemiBold; color: Theme.bright; mono: true
                anchors.verticalCenter: parent.verticalCenter }
        Label { text: Qt.formatDate(root.now, "ddd d MMM"); color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter }
    }

    // ---- right ----
    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: Theme.gap / 2
        layoutDirection: Qt.LeftToRight

        Pill {                                           // CPU, memory, load
            id: sysPill
            visible: root.primary
            active: root.openPanel === "system"
            onClicked: root.panelRequested("system", sysPill)
            Ring { value: System.cpu; color: Theme.cpu; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "cpu"; color: Theme.subtext; font.pixelSize: Theme.smallSize; anchors.verticalCenter: parent.verticalCenter }
            Ring { value: 100 * System.memUsed / System.memTotal; color: Theme.mem; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "mem"; color: Theme.subtext; font.pixelSize: Theme.smallSize; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "load"; color: Theme.subtext; font.pixelSize: Theme.smallSize; anchors.verticalCenter: parent.verticalCenter }
            Label { text: System.load1.toFixed(2); mono: true; anchors.verticalCenter: parent.verticalCenter }
        }
        Pill {                                           // one ring per drive
            id: diskPill
            visible: root.primary && System.disks.length > 0
            active: root.openPanel === "system"
            onClicked: root.panelRequested("system", diskPill)
            Repeater {
                model: System.disks
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    readonly property real p: 100 * modelData.used / modelData.size
                    Ring { value: parent.p; color: Theme.fill(parent.p); anchors.verticalCenter: parent.verticalCenter }
                    Label { text: modelData.device.replace("nvme", "nv").replace(/n1$/, ""); color: Theme.subtext
                            font.pixelSize: Theme.smallSize; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
        Pill {                                           // network
            id: netPill
            visible: root.primary
            active: root.openPanel === "network"
            onClicked: root.panelRequested("network", netPill)
            Glyph { text: Network.kind === "wifi" ? Icons.wifi : Icons.ethernet
                    color: Network.connected ? Theme.net : Theme.overlay; anchors.verticalCenter: parent.verticalCenter }
            Label { text: Network.connected ? "↓ " + Fmt.rate(Network.downRate) : "offline"; mono: true
                    color: Network.connected ? Theme.net : Theme.overlay; anchors.verticalCenter: parent.verticalCenter }
        }
        Pill {                                           // Bluetooth
            id: btPill
            visible: Bluetooth.available
            active: root.openPanel === "bluetooth"
            onClicked: root.panelRequested("bluetooth", btPill)
            Glyph { text: !Bluetooth.enabled ? Icons.bluetoothOff : Bluetooth.connectedCount > 0 ? Icons.bluetoothConnected : Icons.bluetooth
                    color: Bluetooth.enabled ? Theme.bt : Theme.overlay; anchors.verticalCenter: parent.verticalCenter }
            Label {
                readonly property var first: Bluetooth.devices.find(d => d.connected)
                visible: Bluetooth.enabled && first !== undefined
                text: first ? (first.battery >= 0 ? Math.round(first.battery * 100) + "%" : first.name) : ""
                mono: first !== undefined && first.battery >= 0
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Pill {                                           // volume
            id: volPill
            active: root.openPanel === "audio"
            onClicked: root.panelRequested("audio", volPill)
            Glyph { text: Audio.muted ? Icons.volumeOff : Icons.volume; color: Audio.muted ? Theme.overlay : Theme.audio
                    anchors.verticalCenter: parent.verticalCenter }
            Slider { width: 70; value: Audio.volume; onMoved: v => Audio.setVolume(v); anchors.verticalCenter: parent.verticalCenter }
        }
        Pill {                                           // media
            id: mediaPill
            visible: Media.available
            active: root.openPanel === "audio"
            onClicked: root.panelRequested("audio", mediaPill)
            Glyph { text: Media.playing ? Icons.pause : Icons.play; color: Theme.bright; anchors.verticalCenter: parent.verticalCenter
                    TapHandler { onTapped: Media.playPause() } }
            Label { text: Media.title; width: Math.min(implicitWidth, 200); anchors.verticalCenter: parent.verticalCenter }
        }
        Pill {                                           // notifications: count, do-not-disturb
            id: notifyPill
            active: root.openPanel === "notifications"
            onClicked: root.panelRequested("notifications", notifyPill)
            Glyph {
                text: Notifications.dnd ? Icons.bellOff : (Notifications.count > 0 ? Icons.bellBadge : Icons.bell)
                color: Notifications.dnd ? Theme.overlay : (Notifications.count > 0 ? Theme.purple : Theme.subtext)
                anchors.verticalCenter: parent.verticalCenter
            }
            Label { visible: Notifications.count > 0; text: Notifications.count; mono: true
                    anchors.verticalCenter: parent.verticalCenter }
        }
        Pill {                                           // power: session menu (lock ... shut down)
            id: powerPill
            onClicked: root.powerRequested()
            Glyph { text: Icons.power; color: Theme.red; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
