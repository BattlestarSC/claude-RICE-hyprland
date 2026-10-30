// System telemetry from /proc and sysfs: CPU (total, per core, history), load averages,
// memory, AMD GPU (busy, VRAM, temperature) and per-drive disk usage + I/O.
// Plain file reads on timers; no daemons. Data sources: docs/knowledge-base/bar.md.
//
// Interface (mirrored by tests/quickshell/qs/services/System.qml):
//   cpu, cpuHistory[], cores[], threads, load1, load5, load15, memUsed, memTotal (bytes),
//   gpuBusy (%), vramUsed, vramTotal (bytes), gpuTemp (°C), hasGpu,
//   disks[]: { device, mount, used, size, read, write }   (bytes, bytes/s)
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property var cpuHistory: []
    property var cores: []
    property int threads: cores.length
    property real load1: 0
    property real load5: 0
    property real load15: 0
    property real memUsed: 0
    property real memTotal: 1
    property real gpuBusy: 0
    property real vramUsed: 0
    property real vramTotal: 1
    property real gpuTemp: 0
    property bool hasGpu: gpuDir !== ""
    property var disks: []

    readonly property int historyLength: 30
    property string gpuDir: ""          // /sys/class/drm/cardN/device of the amdgpu card
    property string gpuHwmon: ""
    property var _prevCpu: []
    property var _prevIo: ({})
    property real _prevIoTime: 0
    property var _usage: []             // from lsblk, refreshed slowly

    FileView { id: statFile;   path: "/proc/stat";      blockLoading: true }
    FileView { id: loadFile;   path: "/proc/loadavg";   blockLoading: true }
    FileView { id: memFile;    path: "/proc/meminfo";   blockLoading: true }
    FileView { id: ioFile;     path: "/proc/diskstats"; blockLoading: true }
    FileView { id: busyFile;   path: root.gpuDir ? root.gpuDir + "/gpu_busy_percent" : "";   blockLoading: true }
    FileView { id: vramUFile;  path: root.gpuDir ? root.gpuDir + "/mem_info_vram_used" : ""; blockLoading: true }
    FileView { id: vramTFile;  path: root.gpuDir ? root.gpuDir + "/mem_info_vram_total" : ""; blockLoading: true }
    FileView { id: tempFile;   path: root.gpuHwmon ? root.gpuHwmon + "/temp1_input" : "";    blockLoading: true }

    // Find the amdgpu card once: the first DRM device exposing gpu_busy_percent.
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/drm/card*/device; do " +
                  "[ -r \"$d/gpu_busy_percent\" ] && { echo \"$d\"; ls -d \"$d\"/hwmon/hwmon* 2>/dev/null | head -n1; exit 0; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.gpuDir = lines[0] || "";
                root.gpuHwmon = lines[1] || "";
            }
        }
    }

    // Filesystem usage per physical drive (bytes). lsblk reports FSUSED/FSSIZE for mounted
    // filesystems; partitions are summed into their parent disk.
    Process {
        id: lsblk
        command: ["lsblk", "-J", "-b", "-o", "NAME,PKNAME,TYPE,MOUNTPOINTS,FSUSED,FSSIZE"]
        stdout: StdioCollector { onStreamFinished: root._usage = root.parseLsblk(text) }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: lsblk.running = true }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.sample() }

    function sample() {
        for (const f of [statFile, loadFile, memFile, ioFile, busyFile, vramUFile, vramTFile, tempFile])
            if (f.path) f.reload();
        sampleCpu(statFile.text());
        const la = loadFile.text().split(" ");
        load1 = Number(la[0]); load5 = Number(la[1]); load15 = Number(la[2]);
        sampleMem(memFile.text());
        sampleIo(ioFile.text());
        if (gpuDir) {
            gpuBusy = Number(busyFile.text()) || 0;
            vramUsed = Number(vramUFile.text()) || 0;
            vramTotal = Number(vramTFile.text()) || 1;
            gpuTemp = (Number(tempFile.text()) || 0) / 1000;
        }
    }

    function sampleCpu(text) {
        const rows = text.split("\n").filter(l => l.startsWith("cpu"));
        const now = rows.map(l => {
            const v = l.trim().split(/\s+/).slice(1).map(Number);
            const idle = v[3] + (v[4] || 0);                     // idle + iowait
            return [idle, v.reduce((a, b) => a + b, 0)];
        });
        if (_prevCpu.length === now.length) {
            const pct = now.map((s, i) => {
                const dt = s[1] - _prevCpu[i][1], di = s[0] - _prevCpu[i][0];
                return dt > 0 ? Math.max(0, Math.min(100, 100 * (1 - di / dt))) : 0;
            });
            cpu = pct[0];
            cores = pct.slice(1);
            cpuHistory = cpuHistory.concat([cpu]).slice(-historyLength);
        }
        _prevCpu = now;
    }

    function sampleMem(text) {
        const kv = {};
        for (const l of text.split("\n")) {
            const m = l.match(/^(\w+):\s+(\d+)/);
            if (m) kv[m[1]] = Number(m[2]) * 1024;
        }
        memTotal = kv.MemTotal || 1;
        memUsed = memTotal - (kv.MemAvailable || 0);
    }

    function sampleIo(text) {
        const t = Date.now() / 1000;
        const io = {};
        for (const l of text.split("\n")) {
            const f = l.trim().split(/\s+/);
            if (f.length > 10 && /^nvme\d+n\d+$|^sd[a-z]+$/.test(f[2]))
                io[f[2]] = [Number(f[5]) * 512, Number(f[9]) * 512];   // sectors read/written
        }
        const dt = t - _prevIoTime;
        disks = _usage.map(d => {
            const cur = io[d.device], prev = _prevIo[d.device];
            const ok = cur && prev && dt > 0;
            return Object.assign({}, d, {
                read: ok ? Math.max(0, (cur[0] - prev[0]) / dt) : 0,
                write: ok ? Math.max(0, (cur[1] - prev[1]) / dt) : 0,
            });
        });
        _prevIo = io;
        _prevIoTime = t;
    }

    function parseLsblk(text) {
        let doc;
        try { doc = JSON.parse(text); } catch (e) { return _usage; }
        const out = [];
        function walk(dev, disk) {
            const name = disk || dev.name;
            const mounts = (dev.mountpoints || []).filter(m => m);
            if (mounts.length && dev.fssize) {
                let d = out.find(x => x.device === name);
                if (!d) { d = { device: name, mount: "", used: 0, size: 0 }; out.push(d); }
                d.used += Number(dev.fsused) || 0;
                d.size += Number(dev.fssize) || 0;
                const m = mounts.slice().sort((a, b) => a.length - b.length)[0];   // shortest: "/" over "/var/..."
                if (!d.mount || m.length < d.mount.length) d.mount = m;
            }
            for (const c of dev.children || []) walk(c, name);
        }
        for (const dev of doc.blockdevices || [])
            if (dev.type === "disk") walk(dev, null);
        return out.filter(d => d.size > 0).sort((a, b) => a.device.localeCompare(b.device));
    }
}
