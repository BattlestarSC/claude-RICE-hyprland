// Mock of config/quickshell/services/Bluetooth.qml.
pragma Singleton
import QtQuick
QtObject {
    property bool available: true
    property bool enabled: true
    property bool discovering: false
    property var devices: [
        { address: "AA:01", name: "WH-1000XM5", icon: "audio-headset", connected: true, paired: true, pairing: false, battery: 0.78 },
        { address: "AA:02", name: "MX Master 3S", icon: "input-mouse", connected: true, paired: true, pairing: false, battery: 0.15 },
        { address: "AA:03", name: "Xbox Controller", icon: "input-gaming", connected: false, paired: true, pairing: false, battery: -1 },
    ]
    property int connectedCount: devices.filter(d => d.connected).length
    function setEnabled(on) { enabled = on; }
    function scan(on) { discovering = on; }
    function toggle(address) {}
}
