// The bar window for one screen (top layer, reserves space) plus its dropdown popup.
// Workspaces come from Hyprland: this screen's own, so each monitor shows its set (Twin layout).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "rice-bar"
    anchors { top: true; left: true; right: true }
    // Same distance to the screen edge as windows (Hyprland gaps_out = Theme.screenGap); Hyprland
    // adds gaps_out again below the reserved zone, so bar-to-window spacing matches too.
    margins { top: Theme.screenGap; left: Theme.screenGap; right: Theme.screenGap }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight + Theme.screenGap
    color: "transparent"

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property bool primary: screen === Screens.primary

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
        // Flight Deck session menu: lock, log out, suspend, reboot, shut down (bin/rice-menu).
        onPowerRequested: { win.panel = ""; Quickshell.execDetached(["rice-menu", "session"]); }
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
                                notifications: notificationsPanel,
                                audio: audioPanel })[win.panel] || null
        }
    }
    Component { id: systemPanel; SystemPanel {} }
    Component { id: networkPanel; NetworkPanel {} }
    Component { id: bluetoothPanel; BluetoothPanel {} }
    Component { id: audioPanel; AudioPanel {} }
    Component { id: notificationsPanel; NotificationsPanel {} }
}
