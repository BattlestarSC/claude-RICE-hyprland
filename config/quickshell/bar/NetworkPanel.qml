// Network dropdown: interface, addresses, throughput history.
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

PanelCard {
    icon: Network.kind === "wifi" ? Icons.wifi : Icons.ethernet
    iconColor: Theme.net
    title: Network.connected ? "Connected" : "Offline"
    subtitle: Network.connected ? Network.iface + " · " + Network.kind : "no default route"

    component Field: RowLayout {
        property string label
        property string value
        Layout.fillWidth: true
        Label { text: parent.label; color: Theme.subtext; Layout.preferredWidth: 70 }
        Label { text: parent.value; mono: true; Layout.fillWidth: true }
    }
    component Rate: RowLayout {
        property string glyph
        property real rate
        property var history
        property color tint
        spacing: 10
        Layout.fillWidth: true
        Glyph { text: parent.glyph; color: parent.tint; Layout.preferredWidth: 22 }
        Spark { values: parent.history; color: parent.tint; count: 40; barWidth: 4; Layout.fillWidth: true }
        Label { text: Fmt.rate(parent.rate); mono: true; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 80 }
    }

    Field { label: "IPv4"; value: Network.ipv4 || "—" }
    Field { label: "Gateway"; value: Network.gateway || "—" }
    Rate { glyph: Icons.down; rate: Network.downRate; history: Network.downHistory; tint: Theme.green }
    Rate { glyph: Icons.up; rate: Network.upRate; history: Network.upHistory; tint: Theme.yellow }
}
