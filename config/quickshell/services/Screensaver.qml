// Screensaver state. hypridle starts it after 5 minutes idle and stops it on the first input:
//   qs ipc call screensaver start | stop      (config/hypr/hypridle.conf)
// The overlay itself also stops it on any key or click (sky/SaverWindow.qml).
// While active: the sky animates at Config.saverFps and notification popups are held back.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool active: false

    onActiveChanged: {
        Notifications.suppressed = active;
        SkyClock.animating += active ? 1 : -1;   // the saver animates regardless of windows
    }

    IpcHandler {
        target: "screensaver"
        function start(): void { root.active = true; }
        function stop(): void { root.active = false; }
        function toggle(): void { root.active = !root.active; }
        function isActive(): bool { return root.active; }
    }
}
