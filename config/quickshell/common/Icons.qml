// Nerd Font codepoints used by the bar (Symbols Nerd Font; verified against its cmap).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string cpu: ""
    readonly property string memory: "\u{f035b}"
    readonly property string disk: "\u{f02ca}"
    readonly property string gpu: "\u{f08ae}"
    readonly property string ethernet: "\u{f0200}"
    readonly property string wifi: "\u{f05a9}"
    readonly property string bluetooth: "\u{f00af}"
    readonly property string bluetoothOff: "\u{f00b2}"
    readonly property string bluetoothConnected: "\u{f00b1}"
    readonly property string volume: "\u{f057e}"
    readonly property string volumeOff: "\u{f0581}"
    readonly property string play: "\u{f040a}"
    readonly property string pause: "\u{f03e4}"
    readonly property string next: "\u{f04ad}"
    readonly property string previous: "\u{f04ae}"
    readonly property string headphones: "\u{f02cb}"
    readonly property string speaker: "\u{f04c3}"
    readonly property string monitor: "\u{f0379}"
    readonly property string power: "\u{f0425}"
    readonly property string down: "\u{f0045}"
    readonly property string up: "\u{f005d}"
    readonly property string check: "\u{f012c}"

    // BlueZ device icon names -> glyphs.
    function forBluetooth(icon) {
        if (!icon) return bluetooth;
        if (icon.indexOf("headset") >= 0 || icon.indexOf("headphone") >= 0) return headphones;
        if (icon.indexOf("speaker") >= 0 || icon.indexOf("audio") >= 0) return speaker;
        return bluetooth;
    }
    function forSink(name) {
        const n = (name || "").toLowerCase();
        if (n.indexOf("head") >= 0) return headphones;
        if (n.indexOf("hdmi") >= 0 || n.indexOf("displayport") >= 0 || n.indexOf("monitor") >= 0) return monitor;
        return speaker;
    }
}
