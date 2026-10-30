// Mock of config/quickshell/services/System.qml (same interface, fixed sample data).
pragma Singleton
import QtQuick
QtObject {
    property real cpu: 12
    property var cpuHistory: [8, 9, 14, 30, 22, 12, 10, 9, 18, 41, 26, 15, 11, 12, 9, 12, 7, 9, 22, 35, 18, 12, 10, 11, 9, 14, 12, 10, 13, 12]
    property var cores: [18, 7, 12, 4, 31, 9, 6, 14, 22, 3, 8, 11, 5, 19, 7, 10]
    property int threads: 16
    property real load1: 0.82
    property real load5: 0.64
    property real load15: 0.51
    property real memUsed: 9.4 * 1073741824
    property real memTotal: 31.2 * 1073741824
    property real gpuBusy: 4
    property real vramUsed: 1.2 * 1073741824
    property real vramTotal: 16 * 1073741824
    property real gpuTemp: 41
    property bool hasGpu: true
    property var disks: [
        { device: "nvme0n1", mount: "/",      used: 412e9,  size: 1800e9, read: 12e6, write: 3e6 },
        { device: "nvme1n1", mount: "/home",  used: 1100e9, size: 3600e9, read: 0,    write: 1e6 },
        { device: "nvme2n1", mount: "/games", used: 1690e9, size: 1800e9, read: 48e6, write: 0 },
    ]
}
