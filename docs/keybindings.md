# Keybindings

i3's default keymap, carried over to Hyprland 0.57 (decision D12). Source of truth:
[`config/hypr/conf/binds.lua`](../config/hypr/conf/binds.lua). In a session, <kbd>Super+F1</kbd>
shows every bind that has a description (`rice-menu keys`, read live from `hyprctl -j binds`).

`$mod` is **Super**: i3 ships its config with `Mod1` (Alt), and `i3-config-wizard` rewrites it to
whichever key you choose on first start; Super is the usual choice. To use Alt, change one line
(`local mod = "ALT"`). Movement keys are i3's **j k l ;**, not vim's h j k l. In i3, `$mod+h` is
"split horizontal", and it still is here.

## i3 defaults

| Keys | i3 command | Hyprland | Notes |
| --- | --- | --- | --- |
| `$mod+Return` | `exec i3-sensible-terminal` | `exec_cmd("kitty")` | |
| `$mod+Shift+q` | `kill` | `window.close()` | graceful close, like i3 |
| `$mod+d` | `exec dmenu_run` | `exec_cmd("rofi -show drun")` | the Orbit launcher; apps, not raw commands (commands: `$mod+Shift+d`) |
| `$mod+j/k/l/;`, `$mod+arrows` | `focus left/down/up/right` | `focus({ direction })` | inside a group, left/right walk tabs first, then leave the group, like i3 tabbed |
| `$mod+Shift+j/k/l/;`, `+arrows` | `move left/down/up/right` | `window.move({ direction, group_aware = true })` | moves into/out of groups on the way, like i3 containers |
| `$mod+h` | `split h` | `layout("preselect r")` | dwindle has no split containers; this sets where the next window opens |
| `$mod+v` | `split v` | `layout("preselect d")` | same, below |
| `$mod+e` | `layout toggle split` | `layout("togglesplit")` | requires `dwindle.preserve_split = true` |
| `$mod+f` | `fullscreen toggle` | `window.fullscreen({ action = "toggle" })` | |
| `$mod+w` | `layout tabbed` | `group.toggle()` | Hyprland groups are i3's tabbed containers |
| `$mod+s` | `layout stacking` | `group.toggle()` | Hyprland has no stacked layout; same as `$mod+w` |
| `$mod+Shift+space` | `floating toggle` | `window.float({ action = "toggle" })` | |
| `$mod+space` | `focus mode_toggle` | `cycle_next({ tiled })` or `({ floating })` | picks the other layer from the focused window's state |
| `$mod+a` | `focus parent` | **unbound** | no container tree in Hyprland, so no equivalent |
| `$mod+Shift+minus` | `move scratchpad` | `window.move({ workspace = "special:scratchpad" })` | |
| `$mod+minus` | `scratchpad show` | `workspace.toggle_special("scratchpad")` | shows the whole scratchpad, not one window at a time |
| `$mod+1…0` | `workspace number N` | `focus({ workspace = N })` | `0` is workspace 10 |
| `$mod+Shift+1…0` | `move container to workspace` | `window.move({ workspace = N, follow = false })` | does not follow, like i3 |
| `$mod+Shift+c` | `reload` | `reload_config()` | Hyprland also reloads on file save |
| `$mod+Shift+r` | `restart` | `reload_config()` | no in-place restart exists; reload is the closest |
| `$mod+Shift+e` | `i3-nagbar` exit prompt | `rice-menu session` | lock, log out, suspend, reboot, shut down (Flight Deck menu) |
| `$mod+r` | resize mode | submap `resize` | j/k/l/; and arrows, 40 px steps, repeat when held; leave with Return, Escape or `$mod+r` |
| `$mod`+drag | `floating_modifier` | `window.drag()` / `window.resize()` | left button moves, right button resizes; works on tiled windows too |
| Volume / mute keys | `pactl … 10%` | `wpctl … 10%` | PipeWire; same 10% step; work on the lock screen |

## Additions

Keys i3's default config leaves free.

| Keys | Action |
| --- | --- |
| `$mod+Shift+d` | run a command (rofi `run`) |
| `$mod+Shift+x` | lock (`rice-session lock`: `loginctl lock-session` → hypridle → hyprlock; hyprlock directly without logind) |
| `$mod+Shift+v` | clipboard history |
| `$mod+Tab` | window switcher |
| `$mod+Shift+m` | monitor menu: KVM helpers (Phase 1) |
| `$mod+F1` | keybinding cheat sheet |
| `Print` | screenshot menu |
| `$mod+Ctrl+Shift+Left/Right` | send the current workspace to the left or right monitor |
| Media keys | play/pause, next, previous (`playerctl`) |

## Verification

`lua5.4 tests/lua/run.lua config/hypr/conf/binds.lua` loads the file against a stub of the `hl`
API whose dispatcher names are copied from Hyprland v0.57.0's source. It fails on a misspelled
or removed dispatcher, an unknown modifier, or two binds on the same keys, and it runs every
function bind under five window states (none, tiled, floating, first and last tab of a group).
