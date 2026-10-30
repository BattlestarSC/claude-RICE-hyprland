// System dropdown: CPU (total, per core, history), load averages, memory, GPU, every drive.
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

PanelCard {
    icon: Icons.cpu
    iconColor: Theme.cpu
    title: "System"
    subtitle: System.threads + " threads · load " + System.load1.toFixed(2) + " " + System.load5.toFixed(2) + " "
              + System.load15.toFixed(2)

    component Stat: RowLayout {
        property string label
        property string value
        property real pct
        property color fill
        spacing: 10
        Layout.fillWidth: true
        Label { text: parent.label; color: Theme.subtext; Layout.preferredWidth: 58 }
        Meter { value: parent.pct; fill: parent.fill; Layout.fillWidth: true }
        Label { text: parent.value; mono: true; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
    }

    Stat { label: "CPU"; pct: System.cpu; fill: Theme.cpu; value: Fmt.pct(System.cpu) }
    RowLayout {                                  // per-core bars + history
        spacing: 10
        Layout.fillWidth: true
        Item { Layout.preferredWidth: 58 }
        Row {
            spacing: 2
            Layout.fillWidth: true
            Layout.preferredHeight: 18                // a Row's own height is its tallest bar
            Repeater {
                model: System.cores
                Rectangle {
                    width: 6; height: Math.max(2, 18 * modelData / 100)
                    y: 18 - height                        // bottom-aligned
                    radius: 1; color: Theme.cpu; opacity: 0.85
                }
            }
        }
        Spark { values: System.cpuHistory; max: 100; color: Theme.cpu; count: 30; barWidth: 2 }
    }
    RowLayout {                                  // load averages vs thread count
        spacing: 10
        Layout.fillWidth: true
        Label { text: "Load"; color: Theme.subtext; Layout.preferredWidth: 58 }
        Repeater {
            model: [["1m", System.load1], ["5m", System.load5], ["15m", System.load15]]
            RowLayout {
                spacing: 6
                Layout.fillWidth: true
                Meter { value: 100 * modelData[1] / Math.max(1, System.threads); fill: Theme.orange
                        Layout.fillWidth: true; implicitWidth: 40 }
                Label { text: modelData[1].toFixed(2); mono: true; font.pixelSize: Theme.smallSize }
            }
        }
    }
    Stat { label: "Memory"; pct: 100 * System.memUsed / System.memTotal; fill: Theme.mem
           value: Fmt.bytes(System.memUsed) + " / " + Fmt.bytes(System.memTotal, 0) }
    Stat { visible: System.hasGpu; label: "GPU"; pct: System.gpuBusy; fill: Theme.gpu
           value: Fmt.pct(System.gpuBusy) + " · " + Math.round(System.gpuTemp) + "°C" }
    Stat { visible: System.hasGpu; label: "VRAM"; pct: 100 * System.vramUsed / System.vramTotal; fill: Theme.gpu
           value: Fmt.bytes(System.vramUsed) + " / " + Fmt.bytes(System.vramTotal, 0) }

    Label { text: "DRIVES"; color: Theme.overlay; font.pixelSize: Theme.smallSize; font.letterSpacing: 1.5 }
    Repeater {
        model: System.disks
        RowLayout {
            readonly property real p: 100 * modelData.used / modelData.size
            spacing: 10
            Layout.fillWidth: true
            Ring { value: parent.p; color: Theme.fill(parent.p); size: 30 }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                RowLayout {
                    Label { text: modelData.device; mono: true }
                    Label { text: modelData.mount; color: Theme.overlay; Layout.fillWidth: true }
                    Label { text: Fmt.bytes(modelData.used) + " / " + Fmt.bytes(modelData.size); mono: true
                            font.pixelSize: Theme.smallSize; color: Theme.subtext }
                }
                Label { text: "read " + Fmt.rate(modelData.read) + " · write " + Fmt.rate(modelData.write)
                        mono: true; font.pixelSize: Theme.smallSize; color: Theme.overlay }
            }
        }
    }
}
