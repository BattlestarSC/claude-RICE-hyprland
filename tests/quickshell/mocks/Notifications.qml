// Mock of config/quickshell/services/Notifications.qml (same interface, sample data).
pragma Singleton
import QtQuick
QtObject {
    id: root
    function make(id, app, icon, summary, body, urgency, actions, minutesAgo) {
        return { id: id, appName: app, appIcon: icon, summary: summary, body: body, urgency: urgency,
                 image: "", actions: actions.map(t => ({ identifier: t, text: t, invoke() {} })),
                 _time: new Date(Date.now() - minutesAgo * 60000) };
    }
    property var history: [
        make(3, "Blender", "", "Render finished", "scene.blend · frame 240 of 240 · 01:42:13", 1, ["Open output"], 1),
        make(2, "Firefox", "", "Download complete", "ne_50m_land.geojson (2.1 MB)", 1, [], 14),
        make(1, "System", "", "Battery low on WH-1000XM5", "15 % remaining <b>markup must render as text</b>", 2, [], 52),
    ]
    property var popups: history.slice(0, 2)
    property bool dnd: false
    property bool suppressed: false
    property int count: history.length
    function timeOf(n) { return n._time; }
    function dismiss(n) {}
    function clear() {}
    function popupDone(n) {}
    function setDnd(on) { dnd = on; }
}
