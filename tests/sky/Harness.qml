// Test harness: hosts AsciiSky in a plain Qt Quick window so tests/sky/render.py can grab frames.
import QtQuick
import "../../config/quickshell/sky"

Rectangle {
    id: root
    color: "black"
    AsciiSky {
        id: sky
        objectName: "sky"
        anchors.fill: parent
    }
}
