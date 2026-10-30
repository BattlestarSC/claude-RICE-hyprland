// Bluetooth through BlueZ: adapter power, scanning, paired/connected devices with battery.
// Needs bluez + bluez-utils and bluetooth.service enabled (installer step).
//
// Interface (mirrored by tests/quickshell/qs/services/Bluetooth.qml):
//   available, enabled, discovering, connectedCount,
//   devices[]: { address, name, icon, connected, paired, pairing, battery (0..1 or -1) },
//   setEnabled(on), scan(on), toggle(address)   (connect, disconnect, or pair)
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property var _raw: adapter ? adapter.devices.values : []
    readonly property var devices: _raw
        .filter(d => d.paired || d.connected || root.discovering)
        .map(d => ({
            address: d.address,
            name: d.name || d.deviceName || d.address,
            icon: d.icon,
            connected: d.connected,
            paired: d.paired,
            pairing: d.pairing,
            battery: d.batteryAvailable ? d.battery : -1,
        }))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property int connectedCount: devices.filter(d => d.connected).length

    function setEnabled(on) { if (adapter) adapter.enabled = on; }
    function scan(on) { if (adapter) adapter.discovering = on; }
    function toggle(address) {
        const d = _raw.find(x => x.address === address);
        if (!d) return;
        if (d.connected) d.disconnect();
        else if (d.paired) d.connect();
        else d.pair();
    }
}
