// Mock of config/quickshell/services/Network.qml.
pragma Singleton
import QtQuick
QtObject {
    property string iface: "enp5s0"
    property bool connected: true
    property string kind: "wired"
    property string ipv4: "192.168.1.42/24"
    property string gateway: "192.168.1.1"
    property real downRate: 2.4e6
    property real upRate: 180e3
    property var downHistory: [1, 1, 2, 5, 9, 7, 3, 2, 2, 6, 8, 4, 2, 3, 2, 2, 1, 3, 6, 9, 5, 2, 2, 4, 3, 2, 2, 5, 3, 2.4].map(x => x * 1e6)
    property var upHistory: [0, 0, 1, 1, 2, 1, 0, 0, 1, 1, 2, 1, 0, 1, 0, 0, 1, 1, 1, 2, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1].map(x => x * 1.8e5)
}
