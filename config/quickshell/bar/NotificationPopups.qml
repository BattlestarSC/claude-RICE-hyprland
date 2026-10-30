// Notification popups: top-right of the primary monitor, just below the bar, on the Overlay
// layer (above fullscreen apps). The window is only as large as the stack, so it never blocks
// clicks elsewhere. Popups time out after the app's expireTimeout (seconds) or 6 s; critical
// ones stay until closed; hovering a popup holds its timer.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

PanelWindow {
    id: win

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: Theme.screenGap + Theme.barHeight + Theme.gap; right: Theme.screenGap }
    implicitWidth: Theme.panelWidth
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    visible: (Notifications.popups?.length ?? 0) > 0

    Column {
        id: stack
        width: parent.width
        spacing: 8
        Repeater {
            model: Notifications.popups
            NotificationCard {
                id: card
                required property var modelData
                notification: modelData
                width: stack.width
                onCloseClicked: Notifications.dismiss(modelData)
                Timer {
                    running: !card.critical && !card.hovered
                    interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout * 1000 : 6000
                    onTriggered: Notifications.popupDone(card.notification)
                }
            }
        }
    }
}
