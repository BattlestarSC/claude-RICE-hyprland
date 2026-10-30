// Notification daemon (org.freedesktop.Notifications) built on Quickshell's NotificationServer.
// Owns history, popups and do-not-disturb; the UI is bar/NotificationCard + NotificationPopups
// + NotificationsPanel. Only one daemon can own the D-Bus name: do not run mako/dunst as well.
//
// Interface (mirrored by tests/quickshell/mocks/Notifications.qml):
//   history[]  newest first; Notification objects (appName, appIcon, summary, body, urgency,
//              image, actions[] {identifier, text, invoke()})
//   popups[]   the subset currently shown as popups
//   dnd        do-not-disturb: no popups except critical ones (history still fills)
//   count, timeOf(n), dismiss(n), clear(), popupDone(n), setDnd(on)
// IPC: qs ipc call notifications dnd true|false, qs ipc call notifications clear
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var history: []
    property var popups: []
    property bool dnd: false
    property bool suppressed: false             // screensaver running: hold popups
    readonly property int count: history.length
    readonly property int historyLimit: 50
    property var _received: ({})                 // id -> Date

    function timeOf(n) { return _received[n.id] || new Date(); }
    function dismiss(n) { n.dismiss(); }        // removal happens in onClosed below
    function clear() { for (const n of history.slice()) n.dismiss(); }
    function popupDone(n) {
        popups = popups.filter(p => p !== n);
        if (n.transient) n.expire();             // transient: popup only, never kept in history
    }
    function setDnd(on) { dnd = on; if (on) popups = popups.filter(p => p.urgency === NotificationUrgency.Critical); }

    function _forget(n) {
        history = history.filter(h => h !== n);
        popups = popups.filter(p => p !== n);
        delete _received[n.id];
    }

    NotificationServer {
        keepOnReload: true                       // shell reloads keep the history
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false               // plain text: no remote markup or links rendered
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;                    // keep it after the popup closes
            root._received[n.id] = new Date();
            n.closed.connect(() => root._forget(n));
            if (!n.transient && !root.history.includes(n))
                root.history = [n].concat(root.history);
            // Re-emitted after a shell reload (lastGeneration): history only, no second popup.
            const quiet = n.lastGeneration
                || ((root.dnd || root.suppressed) && n.urgency !== NotificationUrgency.Critical);
            if (!quiet && !root.popups.includes(n))
                root.popups = [n].concat(root.popups).slice(0, 5);
            else if (n.transient)
                n.expire();                      // transient and not shown: nothing keeps it
            // Bound the history: expire the oldest (each once; removal happens in onClosed).
            for (const old of root.history.slice(root.historyLimit)) old.expire();
        }
    }

    IpcHandler {
        target: "notifications"
        function dnd(on: bool): void { root.setDnd(on); }
        function clear(): void { root.clear(); }
    }
}
