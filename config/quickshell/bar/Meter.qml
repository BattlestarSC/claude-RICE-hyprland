// Horizontal fill bar (0-100).
import QtQuick
import qs.common

Rectangle {
    property real value: 0
    property color fill: Theme.cyan
    implicitWidth: 120
    implicitHeight: 6
    radius: height / 2
    color: Theme.track
    Rectangle {
        width: parent.width * Math.max(0, Math.min(100, parent.value)) / 100
        height: parent.height
        radius: parent.radius
        color: parent.fill
        Behavior on width { NumberAnimation { duration: 200 } }
    }
}
