// Number formatting for the bar: bytes, rates, percentages, durations.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function bytes(n, digits) {
        const u = ["B", "K", "M", "G", "T"];
        let i = 0;
        while (n >= 1024 && i < u.length - 1) { n /= 1024; i++; }
        return (i === 0 ? Math.round(n) : n.toFixed(digits === undefined ? (n < 10 ? 1 : 0) : digits)) + u[i];
    }
    function rate(n) { return bytes(n) + "/s"; }
    function pct(x) { return Math.round(x) + "%"; }
    // "now", "5m", "2h", "3d" since a Date.
    function ago(date) {
        const s = Math.max(0, (Date.now() - date.getTime()) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }
    function duration(s) {
        s = Math.max(0, Math.floor(s));
        const m = Math.floor(s / 60), r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }
}
