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

### D7. Session start: SDDM (owner's call, 2026-10-29)

- Graphical login via SDDM. Greeter on X11 in v1 (SDDM's default, most tested; requires
  `xorg-server`), Wayland greeter via weston documented as an option (upstream still calls it
  experimental). Space-themed SDDM QML theme is a Phase 3 sub-project.
  Details: [knowledge-base/hardware.md](knowledge-base/hardware.md#sddm).
- **Consequence:** the TTY auto-start in `~/.zprofile` is dropped; enabling SDDM is a prompted system change.

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

## Open

### O3. Status bar: Quickshell vs waybar (next topic)

The owner is interested in Quickshell. Inputs so far: Arch `extra` ships `quickshell` 0.3.1 [S];
per-screen instances suit the KVM hotplug case [BK]; it is a QML framework, so the bar is written
rather than configured. waybar is the configured alternative with a weaker hotplug record [BK].
To be researched properly before deciding.

### O4. Launcher: concept pending (round 2: six concepts)

Round 1 (Glass, Rim, Horizon line): owner liked Rim but wanted icons, and brought two references
(a retro TUI menu, Aylur's "Globes"). Round 2 in [launcher/concepts.html](launcher/concepts.html):
Halo, Orbit, Mission Control (no retro); Terminal Vision, Flight Deck, Waypoint (strong → light retro).
**Engine follows the pick:** Mission Control or a faithful Terminal Vision mean Quickshell (and then
the bar is Quickshell too, settling O3); the others are rofi. `rofi -dmenu` stays for scripts regardless.
Recommendation: **Waypoint** if staying on rofi (it is the requested middle ground); **Mission Control**
if the bar goes Quickshell. Details: [knowledge-base/launcher.md](knowledge-base/launcher.md).

### O5. Notifications

**Recommendation: mako**; swaync if a notification center is wanted. Revisit with O3: a
Quickshell bar can host notifications itself.

### O6. Deploy method: symlink into the repo vs copy

Symlinks make `git pull` an instant update and keep one source of truth, but break if the repo
is moved or deleted. Copy is robust but makes updates explicit. **Blocked on** verifying that
Hyprland's config watcher reacts to edits through symlinks ([knowledge-base/hyprland.md](knowledge-base/hyprland.md)).
Leaning symlink, with the installer recording the repo path and warning if it moves.

### O8. Project name

Used for state paths (`~/.local/state/<name>/`), the theme switcher command, menu script
prefixes and README. Needs a short lowercase name. Placeholder in docs: `<rice>`.

### O9. Scope beyond Hyprland + kitty + zsh for v1

**Recommendation:** v1 = Hyprland, hyprlock, hypridle, hyprpaper, kitty, zsh + starship, bar,
rofi + menus, notifications, SDDM (stock theme), GTK/Qt dark preference. v2: SDDM theme,
neovim/btop/fastfetch themes, Blender UI theme from the palette.

### O10. License

No license yet. Without one, the repo is "all rights reserved" by default. MIT is the common
choice for dotfiles.

### O11. Keymap: i3-compatible?

Coming from i3, the proposal is i3's defaults where Hyprland has an equivalent: `Super+Enter`
terminal, `Super+D` launcher, `Super+Shift+Q` close, `Super+Shift+E` power menu,
`Super+1..0` / `Super+Shift+1..0` workspaces, `Super+H/J/K/L` (and arrows) focus,
`Super+Shift+H/J/K/L` move, `Super+F` fullscreen, `Super+Shift+Space` float. Did you use
i3's `jkl;` or vim `hjkl`? Any custom i3 binds to carry over?

### O12. Hardware details needed

AMD GPU model (ROCm/HIP RT support), exact ProArt model (10-bit, gamut, refresh), KVM model and
whether it is DisplayPort, and whether a dock/MST hub is in the chain.

Closed: O1 → D10, O2 → D7, O7 → D8.
