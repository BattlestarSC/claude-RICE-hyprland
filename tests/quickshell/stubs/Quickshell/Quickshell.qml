// Test stub: the Quickshell global, only what config/quickshell/common uses.
pragma Singleton
import QtQuick
QtObject {
    function env(name) { return name === "HOME" ? "/nonexistent" : ""; }
    function execDetached(command) {}
}
