// Horizontal slider (0-1). Drag, click, or scroll.
import QtQuick
import qs.common

Item {
    id: slider
    property real value: 0
    property color fill: Theme.red
    signal moved(real value)
    implicitWidth: 120
    implicitHeight: 16

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 6; radius: 3
        color: Theme.track
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, slider.value)); height: parent.height; radius: 3
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.red }
                GradientStop { position: 1; color: Theme.purple } }
        }
    }
    Rectangle {
        x: (parent.width - width) * Math.max(0, Math.min(1, slider.value))
        anchors.verticalCenter: parent.verticalCenter
        width: 12; height: 12; radius: 6
        color: Theme.bright
    }
    MouseArea {
        anchors.fill: parent
        function set(mx) { slider.moved(Math.max(0, Math.min(1, mx / width))); }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x); }
        onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
