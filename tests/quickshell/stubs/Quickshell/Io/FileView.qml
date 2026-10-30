// Test stub: Quickshell.Io FileView. Never reads anything, so adapters keep their defaults.
import QtQuick
QtObject {
    property string path
    property bool watchChanges
    property bool printErrors
    default property QtObject adapter
    signal fileChanged()
    function reload() {}
}
