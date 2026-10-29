# Sources

Retrieved 2026-10-29 unless noted. "Primary" = upstream source or upstream documentation repo.

## Primary

| Source | What it established | How to re-check |
| --- | --- | --- |
| `hyprwm/hyprland-wiki` @ `main` (last commit 2026-10-29 "naming-conventions: better explanation for params (#1681)") | Lua config path, `require` semantics, error behavior, binds, dispatchers, rules, events, hyprctl Lua syntax, ecosystem tool config formats | `git clone --depth 1 https://github.com/hyprwm/hyprland-wiki` → `content/` |
| `hyprwm/Hyprland` tag `v0.57.0` | `example/hyprland.lua` (canonical API usage), Lua 5.5 requirement (`CMakeLists.txt`), CLI flags incl. `--verify-config`, `--version-json` (`src/main.cpp`) | `git clone --depth 1 --branch v0.57.0 https://github.com/hyprwm/Hyprland` |
| `kovidgoyal/kitty` @ `master` (2026-10-29) | Option names/defaults: `auto_reload_config`, `background_blur`, `background_opacity`, `cursor_trail`, `shell_integration`, `tab_bar_style`, `reload_config_file` | `kitty/options/definition.py` |

## Secondary (not independently confirmed)

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
