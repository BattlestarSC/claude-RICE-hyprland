// The primary screen = the leftmost one (workspaces 1-5, telemetry pills, notification popups).
// Quickshell.screens order follows output creation and changes with KVM switches, so it is not
// used directly. null while no screen exists (KVM switched away).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var primary: {
        let best = null;
        for (const s of Quickshell.screens)
            if (best === null || s.x < best.x || (s.x === best.x && s.y < best.y)) best = s;
        return best;
    }
}
