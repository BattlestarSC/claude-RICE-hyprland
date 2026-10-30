# Decisions

Architecture decisions and open questions. Each decided entry states the reason and what
would make us revisit it. Open entries list a recommendation; they need the owner's call.

## Decided

### D1. Target Hyprland ≥ 0.57 with Lua config only

- **Why:** 0.57 removed `.conf` support; Arch `extra` is moving to 0.57 now. Supporting 0.55/0.56
  as well would double the test matrix for a Lua API that was still changing.
- **Consequence:** the installer refuses to deploy to Hyprland < 0.57 and says why.
- **Revisit if:** Arch stays on 0.56 for weeks and users hit the gate.

### D2. Official repositories only on the default install path

- **Why:** "git clone and run" on vanilla Arch must not compile anything or depend on AUR
  maintainers. Fewer moving parts, faster, reproducible.
- **Consequence:** components that exist only in the AUR are optional extras behind a prompt.
- **Revisit if:** a must-have component is AUR-only.

### D3. Themes are generated at dev time and committed

- **Why:** installer stays pure bash with no build step; generated files are reviewable; CI can
  detect drift. See [knowledge-base/theming.md](knowledge-base/theming.md).
- **Revisit if:** palette count × app count makes the generated tree unwieldy.

### D4. Installer: pure bash, `set -Eeuo pipefail`, shellcheck-clean, idempotent, backs up before replacing

- **Why:** vanilla Arch ships bash, not python. Re-runs must be safe because "re-run the
  installer" is the universal fix users will try.

### D5. No zsh framework

- **Why:** startup latency and supply-chain surface. Arch packages the plugins we need.
  See [knowledge-base/zsh.md](knowledge-base/zsh.md).

### D6. Readability over effects

- **Why:** the brief is comfort first. Content windows are opaque by default; blur and
  translucency are for chrome (bar, launcher, notifications). Motion blur off. Wobble off.
- **Revisit if:** the owner wants a showier default; effects stay one toggle away either way.

### D7. Login: greetd + ReGreet, running inside Hyprland (2026-10-30; replaces SDDM)

- Owner asked for a graphical login and allowed replacing SDDM if something fits better.
  greetd + ReGreet (both in Arch `extra`) runs the greeter in a minimal Hyprland session, so:
  the greeter uses **the same monitor config** (EDID match, scale 1.5) and the same KVM
  hot-unplug handling as the desktop; no X server is installed; it is themed with GTK4 CSS
  generated from the palette and uses the generated wallpaper. ReGreet's README documents a
  Hyprland 0.57 Lua greeter config.
- SDDM was the original pick (2026-10-29). Against it: its default greeter needs `xorg-server`,
  its Wayland greeter is still "experimental", and theming is a separate QML project.
- **Consequence:** the TTY auto-start in `~/.zprofile` is dropped; enabling greetd is a prompted
  system change. Details: [knowledge-base/hardware.md](knowledge-base/hardware.md#login-greetd--regreet).

### D8. Primary hardware target (owner's machine, 2026-10-29)

- AMD GPU; two 27" 4K ASUS ProArt panels through a KVM whose outputs disappear on switch;
  Blender with HIP/ROCm. NVIDIA is out of scope beyond a detection warning.
- Monitors configured by EDID description at scale 1.5; workspaces bound to monitors in config
  so they survive KVM switches; ROCm is an opt-in installer step.
  Details: [knowledge-base/hardware.md](knowledge-base/hardware.md).

### D9. Palette contrast rules include APCA (round 2)

- **Why:** the owner found Event Horizon more readable and Pulsar more comfortable, the
  opposite of what WCAG ratios predict. APCA explains it: Pulsar's text is past the glare
  threshold (Lc 95) and its accents span Lc 47–82, so some tokens glare while others recede.
  Rules now cap text at Lc 92, require comments ≥ Lc 45, and limit accent spread to Lc 18.
  See [colors/proposals.md](colors/proposals.md).

### D10. Palette: Quasar (owner's call, 2026-10-29)

- `colors/proposals/round2/quasar.toml`: Pulsar ↔ Event Horizon blend (background 30%, text 55%,
  accents 40% toward Event Horizon), accents clamped to APCA Lc 58–74. Passes all 42 rules.
- Next step: promote it to `colors/quasar.toml` as the single source of truth when the theme
  generator lands (Phase 1). Fine-tuning stays possible via the blend dial.

### D11. Keymap: i3 defaults (owner's call, 2026-10-30)

i3's default bindings with `$mod = Super` and `j k l ;` movement; Hyprland extras only on keys
i3 leaves free. Full mapping and the few gaps (no `focus parent`, no stacked layout):
[keybindings.md](keybindings.md).

### D12. Launcher: Orbit for apps, Flight Deck for scripted menus, engine rofi (2026-10-30)

Owner liked Orbit and Flight Deck. Orbit is the `drun` launcher (`$mod+d`); Flight Deck is the
theme for every `rofi -dmenu` menu (`bin/rice-menu`: session, clipboard, windows, keys,
screenshot). Both rendered with real rofi (`tests/rofi-render.sh`). The launcher no longer
forces a bar engine, so O3 is independent again.

### D13. Name and license (owner, 2026-10-30)

Project name stays `claude-RICE-hyprland`; short name `rice` for paths and commands
(`~/.local/state/rice/`, `rice-menu`). Personal use: no license file.

### D14. Bar: Quickshell, Orbit Glass design (owner's call, 2026-10-30)

Frosted-glass pills per monitor (workspaces · clock · system, drives, network, Bluetooth, volume,
media) with live dropdown panels: System (CPU per core + history, load 1/5/15 against thread count,
memory, GPU, VRAM, every drive with usage ring and I/O), Network, **Bluetooth** (power, scan,
connect/disconnect, device battery), Audio (volume, mute, **output selection**, now playing).
Engine Quickshell (Arch `extra`). Code: `config/quickshell/`; rendered for real with mock
services by `tests/quickshell/render.py`. Telemetry pills only on the primary (left) monitor;
the right monitor shows workspaces 6–10, title and clock.
- **Revisit if:** Quickshell breaks across Qt updates in practice (see bar.md, Risk).

### D15. Wallpaper: live ASCII Earth and Moon, GPU shaders in Quickshell (owner, 2026-10-30)

Owner asked for an animated, slowly rotating ASCII Earth/Moon on both 4K monitors, hyper-optimized,
suggesting a compiled language (Zig, OCaml, Haskell, COBOL). Decision: **two GLSL fragment passes
in a Quickshell `Background` layer**, not a CPU program in any language.
- **Why:** the per-frame work is ~29k character cells (scene) + 8.3M pixels (glyph lookup) per
  monitor. Measured on this repo's renderer through Mesa llvmpipe (LLVM-JIT'd SIMD on 4 cores,
  i.e. about as fast as hand-written native CPU code gets): 200–474 ms per 4K frame. On the GPU the
  same shaders are trivially parallel; on Navi 21 they should cost well under 1 ms per frame
  [estimate, not measured on hardware]. A CPU renderer in Zig/OCaml/etc. would also have to upload
  ~33 MB per monitor per frame to a compositor surface; the shader approach uploads nothing.
- **Shape:** pass 1 evaluates the scene once per cell (cols × rows texture: color + ink density);
  pass 2 maps density to a glyph from a font atlas rendered at the exact physical cell size.
  Earth texture from Natural Earth land polygons (public domain). Angles come from the wall clock,
  so both monitors (and restarts) stay in phase; 10 fps; hidden when the monitor's workspace has a
  fullscreen window. Earth day 6 min, clouds 5 min, Moon orbit 30 min (`common/Config.qml`).
- **Default `skyMode: "mirror"`** (the full scene on each monitor); `"span"` treats both monitors
  as one canvas with the Earth across the seam. Owner to confirm.
- **Static art** (`tools/spacegen.py`) stays for hyprlock and the login screen.

### D16. Color depth: 10-bit, not 12 (2026-10-30)

Owner asked for 12-bit if possible. Hyprland's `bitdepth` accepts 8 or 10 only [V: wiki
`monitors/colors.md`]; the DP 1.4 link itself would carry 4K60 at 12 bpc (~18.7 of 25.92 Gbit/s),
so this is a compositor limit. Configured: `bitdepth = 10`, `cm = "srgb"` (`config/hypr/conf/monitors.lua`).

## Open

### ~~O3. Status bar~~ → D14

<details><summary>History</summary>

### O3. Status bar: recommendation made, awaiting confirmation

Owner's requirements: RAM, CPU, load averages, audio (play/pause, output selection, volume),
network, per-NVMe disk usage; inspiration: the "Orbiter" ASCII space rice.
Concepts in [bar/concepts.html](bar/concepts.html): Orbiter, Telemetry, Flight Deck, Orbit Glass,
Twin HUD. **Recommendation: Quickshell, Telemetry design, split per screen (Twin HUD).** waybar
cannot do live dropdown panels or a native output picker. Details: [knowledge-base/bar.md](knowledge-base/bar.md).

</details>

### ~~O4. Launcher~~ → D12

<details><summary>History</summary>

### O4. Launcher: concept pending (round 2: six concepts)

Round 1 (Glass, Rim, Horizon line): owner liked Rim but wanted icons, and brought two references
(a retro TUI menu, Aylur's "Globes"). Round 2 in [launcher/concepts.html](launcher/concepts.html):
Halo, Orbit, Mission Control (no retro); Terminal Vision, Flight Deck, Waypoint (strong → light retro).
**Engine follows the pick:** Mission Control or a faithful Terminal Vision mean Quickshell (and then
the bar is Quickshell too, settling O3); the others are rofi. `rofi -dmenu` stays for scripts regardless.
Recommendation: **Waypoint** if staying on rofi (it is the requested middle ground); **Mission Control**
if the bar goes Quickshell. Details: [knowledge-base/launcher.md](knowledge-base/launcher.md).

</details>

### O5. Notifications

**Recommendation: mako**; swaync if a notification center is wanted. Now that the bar is
Quickshell (D14), a Quickshell notification server is the third option (one theme, one codebase).

### O6. Deploy method: symlink into the repo vs copy

Symlinks make `git pull` an instant update and keep one source of truth, but break if the repo
is moved or deleted. Copy is robust but makes updates explicit. **Blocked on** verifying that
Hyprland's config watcher reacts to edits through symlinks ([knowledge-base/hyprland.md](knowledge-base/hyprland.md)).
Leaning symlink, with the installer recording the repo path and warning if it moves.

### O9. Scope beyond Hyprland + kitty + zsh for v1

**Recommendation:** v1 = Hyprland, hyprlock, hypridle, hyprpaper, kitty, zsh + starship, bar,
rofi + menus, notifications, SDDM (stock theme), GTK/Qt dark preference. v2: SDDM theme,
neovim/btop/fastfetch themes, Blender UI theme from the palette.

### O12. Hardware details still needed

Answered: GPU RX 6000 / Navi 21 (gfx1030), 16 GB; KVM Level1Techs dual-monitor DisplayPort 1.4
(two links per PC, no EDID emulation). Still open: exact ProArt model (true 10-bit or 8-bit+FRC,
native gamut, refresh); it decides `cm` (see D16) and whether 10-bit stays on.

Closed: O1 → D10, O2 → D7, O3 → D14, O4 → D12, O7 → D8, O8 → D13, O10 → D13, O11 → D11.
