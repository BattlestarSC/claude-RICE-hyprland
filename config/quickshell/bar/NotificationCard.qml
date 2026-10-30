// One notification, used both as a popup and in the history panel.
// Text is always rendered as plain text: apps may send markup even when the server advertises
// none, and a notification must never render remote rich text or links.
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

Rectangle {
    id: card
    required property var notification
    property bool compact: false                 // history list: tighter, no image
    readonly property bool critical: notification.urgency === 2
    readonly property var actions: (notification.actions || []).filter(a => a.identifier !== "default")
    readonly property var defaultAction: (notification.actions || []).find(a => a.identifier === "default")
    readonly property alias hovered: hover.hovered
    signal closeClicked()

    implicitWidth: Theme.panelWidth
    implicitHeight: col.implicitHeight + 2 * pad
    readonly property int pad: compact ? 10 : 12
    radius: 12
    color: hover.hovered ? Theme.glassField : Theme.glass
    border.width: 1
    border.color: critical ? Theme.red : Theme.glassEdge

    HoverHandler { id: hover }
    TapHandler {
        onTapped: if (card.defaultAction) card.defaultAction.invoke(); else card.closeClicked()
    }

    RowLayout {
        anchors { fill: parent; margins: card.pad }
        spacing: 10

        Image {
            source: card.compact ? "" : (card.notification.image || "")
            visible: status === Image.Ready
            Layout.preferredWidth: 40; Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignTop
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(80, 80)
            asynchronous: true
        }

        ColumnLayout {
            id: col
            spacing: 3
            Layout.fillWidth: true

            RowLayout {
                spacing: 6
                Layout.fillWidth: true
                Glyph { text: card.critical ? Icons.bellBadge : Icons.bell; color: card.critical ? Theme.red : Theme.purple
                        font.pixelSize: Theme.smallSize + 2 }
                Label { text: card.notification.appName || "Notification"; textFormat: Text.PlainText
                        color: Theme.overlay; font.pixelSize: Theme.smallSize; Layout.fillWidth: true }
                Label { text: Fmt.ago(Notifications.timeOf(card.notification)); color: Theme.overlay
                        font.pixelSize: Theme.smallSize }
                Glyph {
                    text: Icons.close; font.pixelSize: Theme.smallSize + 2
                    color: closeHover.hovered ? Theme.red : Theme.overlay
                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: card.closeClicked() }
                }
            }
            Label {
                text: card.notification.summary; textFormat: Text.PlainText
                color: Theme.bright; font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Label {
                text: card.notification.body; textFormat: Text.PlainText
                visible: text !== ""
                color: Theme.subtext; wrapMode: Text.Wrap; maximumLineCount: card.compact ? 2 : 4
                Layout.fillWidth: true
            }
            Flow {
                visible: card.actions.length > 0
                spacing: 6
                Layout.fillWidth: true
                Layout.topMargin: 4
                Repeater {
                    model: card.actions
                    Rectangle {
                        required property var modelData
                        implicitWidth: actionLabel.implicitWidth + 20
                        implicitHeight: 24
                        radius: 12
                        color: actionHover.hovered ? Theme.selection : Theme.glassField
                        border.width: 1
                        border.color: Theme.glassEdge
                        Label { id: actionLabel; anchors.centerIn: parent; text: modelData.text; textFormat: Text.PlainText
                                font.pixelSize: Theme.smallSize }
                        HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: modelData.invoke() }
                    }
                }
            }
        }
    }
}
