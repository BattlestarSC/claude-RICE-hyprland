// Circular gauge with the value in the middle (0-100).
import QtQuick
import QtQuick.Shapes
import qs.common

Item {
    id: ring
    property real value: 0
    property color color: Theme.cyan
    property real size: 22
    property real thickness: 3
    property bool showValue: true
    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Theme.track; strokeWidth: ring.thickness; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: (ring.size - ring.thickness) / 2
                           radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: ring.color; strokeWidth: ring.thickness; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: (ring.size - ring.thickness) / 2
                           radiusY: radiusX; startAngle: -90; sweepAngle: 3.6 * Math.max(0, Math.min(100, ring.value)) }
        }
    }
    Text {
        visible: ring.showValue
        anchors.centerIn: parent
        text: Math.round(ring.value)
        font.family: Theme.mono
        font.pixelSize: ring.size * 0.38
        color: Theme.text
    }
}
