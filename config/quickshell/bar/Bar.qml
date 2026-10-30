// The bar window for one screen (top layer, reserves space) plus its dropdown popup.
// Workspaces come from Hyprland: this screen's own, so each monitor shows its set (Twin layout).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "rice-bar"
    anchors { top: true; left: true; right: true }
    margins { top: Theme.gap / 2; left: Theme.gap; right: Theme.gap }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight + Theme.gap / 2
    color: "transparent"

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property bool primary: Quickshell.screens.length < 2 || screen === Quickshell.screens[0]

    property string panel: ""
    property Item panelAnchor: null

    BarContent {
        id: content
        anchors.fill: parent
        primary: win.primary
        openPanel: win.panel
        title: Hyprland.activeToplevel && Hyprland.activeToplevel.workspace
               && Hyprland.activeToplevel.workspace.monitor === win.monitor ? Hyprland.activeToplevel.title : ""
        workspaces: {
            const first = win.primary ? 1 : Config.workspacesPerMonitor + 1;
            const out = [];
            for (let id = first; id < first + Config.workspacesPerMonitor; id++) {
                const ws = Hyprland.workspaces.values.find(w => w.id === id);
                out.push({ id: id, active: ws !== undefined && win.monitor && ws === win.monitor.activeWorkspace,
                           occupied: ws !== undefined && ws.toplevels.values.length > 0 });
            }
            return out;
        }
        onWorkspaceClicked: id => Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })")
        onPanelRequested: (name, anchor) => {
            win.panelAnchor = anchor;
            win.panel = win.panel === name ? "" : name;
        }
    }

    PopupWindow {
        visible: win.panel !== "" && win.panelAnchor !== null
        anchor.item: win.panelAnchor
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: Theme.gap
        grabFocus: true
        color: "transparent"
        implicitWidth: loader.implicitWidth
        implicitHeight: loader.implicitHeight
        onVisibleChanged: if (!visible) win.panel = ""

        Loader {
            id: loader
            sourceComponent: ({ system: systemPanel, network: networkPanel, bluetooth: bluetoothPanel,
                                audio: audioPanel })[win.panel] || null
        }
    }
    Component { id: systemPanel; SystemPanel {} }
    Component { id: networkPanel; NetworkPanel {} }
    Component { id: bluetoothPanel; BluetoothPanel {} }
    Component { id: audioPanel; AudioPanel {} }
}
