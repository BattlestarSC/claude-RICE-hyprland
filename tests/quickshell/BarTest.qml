// Renders the real Orbit Glass bar and all four dropdown panels over an ASCII sky frame.
import QtQuick
import qs.common
import qs.bar
import qs.services

Rectangle {
    id: root
    color: Theme.crust
    property url background
    // Instantiates Config (JSON settings through the Quickshell.Io stubs) so it is load-tested too.
    readonly property string settings: Config.skyMode + " " + Config.skyLayout + " " + Config.skyFps

    Image { anchors.fill: parent; source: root.background; fillMode: Image.PreserveAspectCrop }

    BarContent {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: Theme.screenGap
                  leftMargin: Theme.screenGap; rightMargin: Theme.screenGap }
        height: Theme.barHeight
        title: "kitty — ~/claude-RICE-hyprland"
        openPanel: "notifications"
        now: new Date(2026, 9, 30, 0, 42)
        workspaces: [{ id: 1, active: false, occupied: true }, { id: 2, active: false, occupied: true },
                     { id: 3, active: true, occupied: true }, { id: 4, active: false, occupied: false },
                     { id: 5, active: false, occupied: true }]
    }
    Row {
        anchors { top: parent.top; right: parent.right; topMargin: Theme.barHeight + 2 * Theme.gap; rightMargin: Theme.gap }
        spacing: 2 * Theme.gap
        SystemPanel {}
        NetworkPanel {}
        BluetoothPanel {}
        AudioPanel {}
        NotificationsPanel {}
    }
    // Popups as NotificationPopups.qml stacks them (that file itself needs Quickshell's PanelWindow).
    Column {
        anchors { top: parent.top; left: parent.left; topMargin: Theme.barHeight + 2 * Theme.gap; leftMargin: Theme.gap }
        width: Theme.panelWidth
        spacing: 8
        Repeater {
            model: Notifications.popups
            NotificationCard { required property var modelData; notification: modelData; width: Theme.panelWidth }
        }
    }
}
