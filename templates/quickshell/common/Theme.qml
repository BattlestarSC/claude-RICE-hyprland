// {{ name }} palette and the bar's design tokens. Singleton: `import qs.common`, then `Theme.red`.
// Colors are generated; fonts and sizes live here too (one token file, as in Orbiter).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Base ramp
    readonly property color crust:    "{{ crust | qcolor }}"
    readonly property color mantle:   "{{ mantle | qcolor }}"
    readonly property color base:     "{{ base | qcolor }}"
    readonly property color surface0: "{{ surface0 | qcolor }}"
    readonly property color surface1: "{{ surface1 | qcolor }}"
    readonly property color surface2: "{{ surface2 | qcolor }}"
    readonly property color overlay:  "{{ overlay | qcolor }}"
    readonly property color subtext:  "{{ subtext | qcolor }}"
    readonly property color text:     "{{ text | qcolor }}"
    readonly property color bright:   "{{ bright | qcolor }}"

    // Accents
    readonly property color red:    "{{ red | qcolor }}"
    readonly property color orange: "{{ orange | qcolor }}"
    readonly property color yellow: "{{ yellow | qcolor }}"
    readonly property color green:  "{{ green | qcolor }}"
    readonly property color cyan:   "{{ cyan | qcolor }}"
    readonly property color blue:   "{{ blue | qcolor }}"
    readonly property color purple: "{{ purple | qcolor }}"
    readonly property color pink:   "{{ pink | qcolor }}"

    // Glass (Orbit Glass bar): translucent fills; the blur comes from Hyprland layer rules.
    readonly property color glass:      "{{ base | qcolor:0.74 }}"
    readonly property color glassEdge:  "{{ bright | qcolor:0.10 }}"
    readonly property color glassField: "{{ crust | qcolor:0.55 }}"
    readonly property color selection:  "{{ red | qcolor:0.20 }}"
    readonly property color track:      "{{ surface1 | qcolor }}"

    // Semantic
    readonly property color cpu:  cyan
    readonly property color mem:  purple
    readonly property color gpu:  blue
    readonly property color net:  green
    readonly property color bt:   blue
    readonly property color audio: red
    function fill(pct) { return pct >= 90 ? red : pct >= 75 ? yellow : green }   // disks, traffic light

    // Type
    readonly property string sans: "IBM Plex Sans"
    readonly property string mono: "IBM Plex Mono"
    readonly property string icons: "Symbols Nerd Font"
    readonly property int fontSize: 13          // logical px; x1.5 on the 4K panels
    readonly property int smallSize: 11

    // Geometry (logical px)
    readonly property int barHeight: 34
    readonly property int gap: 10               // matches Hyprland gaps_out
    readonly property int pillPadding: 12
    readonly property int panelRadius: 16
    readonly property int panelWidth: 380
}
