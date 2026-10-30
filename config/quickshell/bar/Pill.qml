// A frosted pill: the unit the Orbit Glass bar is built from. Click opens its panel.
import QtQuick
import qs.common

Rectangle {
    id: pill
    default property alias content: row.data
    property bool active: false                 // its panel is open
    property bool interactive: true
    signal clicked()

    implicitWidth: row.implicitWidth + 2 * Theme.pillPadding
    implicitHeight: Theme.barHeight - 4
    radius: height / 2
    color: hover.hovered && interactive ? Qt.lighter(Theme.glass, 1.25) : Theme.glass
    border.width: 1
    border.color: active ? Theme.red : Theme.glassEdge
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
    HoverHandler { id: hover; cursorShape: pill.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { enabled: pill.interactive; onTapped: pill.clicked() }
}
