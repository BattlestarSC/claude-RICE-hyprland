# Sources

Retrieved 2026-10-29 unless noted. "Primary" = upstream source or upstream documentation repo.

## Primary

| Source | What it established | How to re-check |
| --- | --- | --- |
| `hyprwm/hyprland-wiki` @ `main` (last commit 2026-10-29 "naming-conventions: better explanation for params (#1681)") | Lua config path, `require` semantics, error behavior, binds, dispatchers, rules, events, hyprctl Lua syntax, ecosystem tool config formats | `git clone --depth 1 https://github.com/hyprwm/hyprland-wiki` → `content/` |
| `hyprwm/Hyprland` tag `v0.57.0` | `example/hyprland.lua` (canonical API usage), Lua 5.5 requirement (`CMakeLists.txt`), CLI flags incl. `--verify-config`, `--version-json` (`src/main.cpp`) | `git clone --depth 1 --branch v0.57.0 https://github.com/hyprwm/Hyprland` |
| `kovidgoyal/kitty` @ `master` (2026-10-29) | Option names/defaults: `auto_reload_config`, `background_blur`, `background_opacity`, `cursor_trail`, `shell_integration`, `tab_bar_style`, `reload_config_file` | `kitty/options/definition.py` |
| `hyprwm/Hyprland` `v0.57.0` `src/state/FallbackState.cpp`, `src/state/workspace/LifecyclePolicy.cpp`, `LifecyclePolicyAdapter.cpp` | Monitor hot-unplug: `FALLBACK` headless output, workspace return keyed by connector name | sparse checkout `src/state` |
| `davatorium/rofi` @ `master` (2026-10-29) | Wayland layer surface namespace `rofi`, anchored to all edges; rasi gradients, `url()` images, box widgets; default placeholder and drun format | `doc/rofi-theme.5.markdown`, `doc/default_theme.rasi`, `source/wayland/display.c` |
| `sddm/sddm` @ `develop` (2026-10-20) | `DisplayServer` default `x11`; Wayland `CompositorCommand` default `weston --shell=kiosk`; `EnableHiDPI` default true; Wayland greeter "experimental" | `src/common/Configuration.h`, `ChangeLog` |
| `quickshell-mirror/quickshell` @ 2026-10-21 (tag v0.3.2) | modules (pipewire, mpris, networking=NetworkManager, bluetooth, session lock, greetd, background effect), writable `preferredDefaultAudioSink`, layer enum, Hyprland `usingLua` | `src/services`, `src/network/module.md`, `src/wayland/*` |
| `Alexays/Waybar` man pages @ 2026-10-28 (0.15.0) | module list, `disk` per path, `cpu` load fields, static XML `menu`, `cpu-graph`/`custom-graph` | `man/*.5.scd` |
| `hyprwm/Hyprland` v0.57.0 `src/ipc/s1/Commands.cpp` | `hyprctl -j binds` fields (`modmask`, `key`, `description`, `has_description`, `submap`) | |
| APCA-W3 0.0.98G constants | `tools/palette.py` `apca()`; checked against reference values (`#888` on `#fff` = 63.06, `#fff` on `#888` = −68.54) | |

## Secondary (not independently confirmed)

| Source | Claim |
| --- | --- |
| [rofi 2.0.0 release (newreleases.io)](https://newreleases.io/project/github/davatorium/rofi/release/2.0.0) | 2025-09-01; Wayland port merged into mainline; meson only; no IMDKit on Wayland |
| [archlinux.org: quickshell](https://archlinux.org/packages/extra/x86_64/quickshell/) | `quickshell` 0.3.1 in `extra` |
| [archlinux.org: blender](https://archlinux.org/packages/extra/x86_64/blender/), [ArchWiki: Blender](https://wiki.archlinux.org/title/Blender) | `hip-runtime-amd` and `hiprt` optdepends; GFX9/CDNA/RDNA supported; HIP viewport issues |
| [noctalia-qs AUR](https://aur.archlinux.org/packages/noctalia-qs?all_deps=1) | Quickshell-based shells crashing when quickshell isn't rebuilt after Qt updates (motivation for a fork) |

| [Level1Techs DP 1.4 dual-monitor KVM store page](https://www.store.level1techs.com/products/p/14-kvm-switch-dual-monitor-2computer-z5erd-n6mbj), [L1T forum: displays disconnect on switch](https://forum.level1techs.com/t/level-1-techs-kvm-switch-displays-disconnect-on-switch/150855) | No monitor emulation on DP 1.4 KVMs; DP 1.2 repeater recommended for emulation |
| [r/unixporn "Orbiter"](https://www.reddit.com/r/unixporn/) (text supplied by the owner) | ASCII shader wallpaper, QML bar, token-file theming |

## Secondary, round 1

| Source | Claim |
| --- | --- |
| [hypr.land/news/update57](https://hypr.land/news/update57/) (via search summary; site not reachable from the build environment) | 0.57 released 2026-10-28; `.conf` no longer supported; `hl.reload_config()`; config unload event |
| [hypr.land/news/update55](https://hypr.land/news/update55/) (via search summary) | Lua introduced in 0.55 (2026-05-09); removed `dwindle:pseudotile`, `decoration:shadow:ignore_window` |
| [linuxcompatible.org: Hyprland 0.57.0 released](https://www.linuxcompatible.org/story/hyprland-0570-released-legacy-conf-dropped-window-wobble-arrives/) | No automated converter; window wobble added |
| [GitHub discussion hyprwm/Hyprland#14463](https://github.com/hyprwm/Hyprland/discussions/14463) | Request for a hyprlang→Lua export command |
| [archlinux.org/packages/extra/x86_64/hyprland](https://archlinux.org/packages/extra/x86_64/hyprland/) (via search) | `0.56.2-4` in `extra` (built 2026-09-30) |
| [arch-commits list](http://www.mail-archive.com/arch-commits@lists.archlinux.org/msg1238500.html) | Packaging tag `0.57.0-1` pushed 2026-10-28 |
| [hypr.land/news/update53](https://hypr.land/news/update53/), [linuxiac](https://linuxiac.com/hyprland-0-53-lands-with-window-rule-rewrite-and-dozens-of-fixes/) | 0.53 window-rule overhaul, `windowrulev2` removed |

## Not reachable from the build environment

`wiki.hypr.land`, `hypr.land`, `archlinux.org`, `wiki.archlinux.org`, `gitlab.archlinux.org`.
Anything that depends on Arch package contents or file paths is therefore marked
[BK]/[TODO-verify] and must be checked in an `archlinux:latest` container or on hardware.
