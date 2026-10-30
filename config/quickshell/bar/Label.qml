// Bar text. `mono` for numbers that change, so the layout does not jitter.
import QtQuick
import qs.common

Text {
    property bool mono: false
    font.family: mono ? Theme.mono : Theme.sans
    font.pixelSize: Theme.fontSize
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
