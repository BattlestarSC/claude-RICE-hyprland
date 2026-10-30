// Sparkline as thin bars: history of values, newest on the right.
import QtQuick
import qs.common

Item {
    id: spark
    property var values: []
    property real max: 0                         // 0 = auto
    property color color: Theme.cyan
    property int count: 30
    property real barWidth: 3
    readonly property real peak: max > 0 ? max : Math.max(1e-9, ...values.concat([1e-9]))
    implicitWidth: bars.implicitWidth
    implicitHeight: 18

    Row {
        id: bars
        anchors.fill: parent
        spacing: 1
        Repeater {
            model: spark.count
            Rectangle {
                readonly property int i: index - (spark.count - spark.values.length)
                readonly property real v: i >= 0 ? spark.values[i] : 0
                width: spark.barWidth
                height: Math.max(1, spark.height * Math.min(1, v / spark.peak))
                y: spark.height - height
                radius: 1
                color: i >= 0 ? spark.color : Theme.track
                opacity: 0.4 + 0.6 * (index / spark.count)
            }
        }
    }
}
