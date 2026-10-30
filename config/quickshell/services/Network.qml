// Network: default-route interface, IPv4 address and throughput. Works with any network stack
// (NetworkManager, systemd-networkd, iwd): it reads /proc and /sys and asks `ip` for addresses.
//
// Interface (mirrored by tests/quickshell/qs/services/Network.qml):
//   connected, iface, kind ("wired" | "wifi"), ipv4, gateway,
//   downRate, upRate (bytes/s), downHistory[], upHistory[]
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string iface: ""
    readonly property bool connected: iface !== ""
    readonly property string kind: iface.startsWith("wl") ? "wifi" : "wired"
    property string ipv4: ""
    property string gateway: ""
    property real downRate: 0
    property real upRate: 0
    property var downHistory: []
    property var upHistory: []
    readonly property int historyLength: 30

    property real _rx: -1
    property real _tx: -1
    property real _t: 0

    FileView { id: routeFile; path: "/proc/net/route"; blockLoading: true }
    FileView { id: rxFile; path: root.iface ? "/sys/class/net/" + root.iface + "/statistics/rx_bytes" : ""; blockLoading: true }
    FileView { id: txFile; path: root.iface ? "/sys/class/net/" + root.iface + "/statistics/tx_bytes" : ""; blockLoading: true }

    Process {
        id: addr
        command: ["ip", "-j", "-4", "addr", "show", "dev", root.iface]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(text)[0].addr_info.find(a => a.family === "inet");
                    root.ipv4 = info ? info.local + "/" + info.prefixlen : "";
                } catch (e) { root.ipv4 = ""; }
            }
        }
    }
    onIfaceChanged: { _rx = -1; if (iface) addr.running = true; }
    Timer { interval: 30000; running: root.connected; repeat: true; onTriggered: addr.running = true }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.sample() }

    function sample() {
        routeFile.reload();
        // Default route: Destination 00000000. Gateway is little-endian hex.
        const def = routeFile.text().split("\n").slice(1).map(l => l.trim().split(/\s+/))
            .find(f => f[1] === "00000000");
        iface = def ? def[0] : "";
        if (def) {
            const g = def[2];
            gateway = [6, 4, 2, 0].map(i => parseInt(g.substr(i, 2), 16)).join(".");
        }
        if (!iface) { downRate = upRate = 0; return; }
        rxFile.reload(); txFile.reload();
        const rx = Number(rxFile.text()), tx = Number(txFile.text()), t = Date.now() / 1000;
        if (_rx >= 0 && t > _t) {
            downRate = Math.max(0, (rx - _rx) / (t - _t));
            upRate = Math.max(0, (tx - _tx) / (t - _t));
            downHistory = downHistory.concat([downRate]).slice(-historyLength);
            upHistory = upHistory.concat([upRate]).slice(-historyLength);
        }
        _rx = rx; _tx = tx; _t = t;
    }
}
