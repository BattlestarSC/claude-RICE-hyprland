// Notifications dropdown: history (newest first), do-not-disturb, clear all.
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

PanelCard {
    icon: Notifications.dnd ? Icons.bellOff : Icons.bell
    iconColor: Notifications.dnd ? Theme.overlay : Theme.purple
    title: "Notifications"
    subtitle: (Notifications.count === 0 ? "nothing new" : Notifications.count + " in history")
              + (Notifications.dnd ? " · do not disturb" : "")
    headerExtra: [
        Label { text: "Quiet"; color: Theme.subtext; font.pixelSize: Theme.smallSize; height: 18 },
        Toggle { checked: Notifications.dnd; onToggled: on => Notifications.setDnd(on) }
    ]

    Label {
        visible: Notifications.count === 0
        text: "All clear."
        color: Theme.overlay
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 8; Layout.bottomMargin: 8
    }

    ListView {
        id: list
        visible: Notifications.count > 0
        model: Notifications.history
        spacing: 8
        clip: true
        interactive: contentHeight > height
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 520)
        delegate: NotificationCard {
            required property var modelData
            notification: modelData
            compact: true
            width: list.width
            onCloseClicked: Notifications.dismiss(modelData)
        }
    }

    Rectangle {
        visible: Notifications.count > 0
        Layout.fillWidth: true
        implicitHeight: 30
        radius: 15
        color: clearHover.hovered ? Theme.selection : Theme.glassField
        border.width: 1
        border.color: Theme.glassEdge
        Row {
            anchors.centerIn: parent
            spacing: 8
            Glyph { text: Icons.clearAll; color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Clear all"; anchors.verticalCenter: parent.verticalCenter }
        }
        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Notifications.clear() }
    }
}
