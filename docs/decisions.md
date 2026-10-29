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

## Open

### O1. Color scheme

Four proposals in [colors/proposals.md](colors/proposals.md).
**Recommendation: Nebula.** Blends are possible.

### O2. How the session starts

| Option | Notes |
| --- | --- |
| **TTY + auto `start-hyprland` on VT1 (recommended)** | zero extra packages, no `/etc` changes |
| greetd + tuigreet | small, Wayland-native; needs `/etc/greetd/config.toml` + service |
| SDDM | heavier, separate theming effort |

### O3. Status bar

**Recommendation: waybar.** In `extra`, CSS-themed (direct palette mapping), mature, Hyprland
workspace module. Alternatives: a Quickshell/AGS shell (far more work, AUR-heavy), or none.

### O4. Launcher

| Option | Notes |
| --- | --- |
| hyprlauncher | native, themed by `hyprtoolkit.conf` (same file themes the polkit dialog); Hyprland's emergency bind expects it |
| fuzzel | simple ini theming, very fast, dmenu mode for scripts (power menu, clipboard) |
| rofi | most features and themes, heavier config |

**Recommendation:** hyprlauncher for apps (one theme file covers several hypr tools) plus
fuzzel in dmenu mode for scripted menus, if hyprlauncher lacks a dmenu mode. [TODO-verify]

### O5. Notifications

**Recommendation: mako** (small, ini config, D-Bus activated). swaync if you want a
notification center / control panel.

### O6. Deploy method: symlink into the repo vs copy

Symlinks make `git pull` an instant update and keep one source of truth, but break if the repo
is moved or deleted. Copy is robust but makes updates explicit. **Blocked on** verifying that
Hyprland's config watcher reacts to edits through symlinks ([knowledge-base/hyprland.md](knowledge-base/hyprland.md)).
Leaning symlink, with the installer recording the repo path and warning if it moves.

### O7. NVIDIA scope for v1

Detect and warn only, or automate driver + env setup? Automating is a large, hardware-specific
surface. **Recommendation:** detect and warn in v1, automate in a later phase with hardware to test on.

### O8. Project name

Used for state paths (`~/.local/state/<name>/`), the theme switcher command, and README. Needs a short
lowercase name. Placeholder in docs: `<rice>`.

### O9. Scope beyond Hyprland + kitty + zsh for v1

Candidates: neovim theme, btop, GTK/Qt theming, fastfetch, file manager (thunar/yazi), browser
(none; only GTK dark preference). **Recommendation:** v1 = Hyprland, hyprlock, hypridle,
hyprpaper, kitty, zsh + starship, waybar, launcher, notifications, GTK/Qt dark preference.
Everything else in v2.

### O10. License

No license yet. Without one, the repo is "all rights reserved" by default. MIT is the common
choice for dotfiles.
