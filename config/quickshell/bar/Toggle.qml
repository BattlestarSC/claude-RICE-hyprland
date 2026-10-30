// On/off switch.
import QtQuick
import qs.common

Rectangle {
    id: t
    property bool checked: false
    signal toggled(bool on)
    implicitWidth: 34; implicitHeight: 18; radius: 9
    gradient: Gradient { orientation: Gradient.Horizontal
        GradientStop { position: 0; color: t.checked ? Theme.red : Theme.surface2 }
        GradientStop { position: 1; color: t.checked ? Theme.purple : Theme.surface2 } }
    Rectangle {
        width: 12; height: 12; radius: 6; y: 3
        x: t.checked ? parent.width - width - 3 : 3
        color: t.checked ? Theme.bright : Theme.subtext
        Behavior on x { NumberAnimation { duration: 120 } }
    }
    TapHandler { onTapped: t.toggled(!t.checked) }
}
