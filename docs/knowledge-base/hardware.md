# Target hardware: dual 4K via KVM, AMD GPU, ROCm

The owner's machine. The rice must work well here first; other hardware is best-effort.

| Component | Detail | Still unknown |
| --- | --- | --- |
| Displays | 2 × ASUS ProArt 27" 4K, **IPS** (owner, 2026-10-30) | exact model (10-bit? wide gamut? refresh?) |
| Connection | Level1Techs dual-monitor DisplayPort 1.4 KVM: two DP links per PC, **outputs disappear when switched away** (no EDID emulation, confirmed by the vendor) | ProArt exact model |
| GPU | AMD RX 6000 series, Navi 21 (gfx1030), 16 GB VRAM | exact SKU (6800 / 6800 XT / 6900 XT / 6950 XT) does not change anything below |
| Compute | HIP / ROCm for Blender Cycles | |
| Login | greetd + ReGreet inside Hyprland (D7) | |

## Displays

### Identify by description, not by port

`hl.monitor({ output = "desc:..." })` matches the EDID description, which includes the serial
number, so two identical ProArt panels stay distinguishable and keep their position even if
cables are swapped between GPU ports. [V: hyprland-wiki `monitors/output-selection.md`, `_index.md`, 2026-10-29]

Capture (2026-10-30): the installer runs on a TTY where Hyprland is not running, so it cannot
read them. `rice-monitors --auto` runs from autostart at the first login and fills in
`DESC_LEFT`/`DESC_RIGHT` in `~/.config/hypr/conf/monitors.lua` (left = the panel with the smaller
x), once; `rice-monitors --swap` exchanges them; `rice-monitors --greeter` copies the file to
`/etc/greetd/`. All three are in `rice-menu monitors` (Super+Shift+M). Re-running the installer
keeps captured values.

```lua
-- Real strings come from `hyprctl monitors all -j` (.description); bin/rice-monitors writes them at the first login.
hl.monitor({ output = "desc:ASUSTek COMPUTER INC PA27xxxx SERIAL_LEFT",  mode = "3840x2160@60", position = "0x0",    scale = 1.5 })
hl.monitor({ output = "desc:ASUSTek COMPUTER INC PA27xxxx SERIAL_RIGHT", mode = "3840x2160@60", position = "2560x0", scale = 1.5 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })  -- anything else
```

### Scale

27" at 3840×2160 is ~163 PPI. Scale **1.5** gives a 2560×1440 logical desktop per panel, the
same density as a 27" 1440p screen. 1.5 divides 3840 and 2160 exactly, so no fractional-pixel
rounding. Position of the second monitor is in **logical** pixels (`2560x0`, not `3840x0`). [BK, arithmetic]

Fractional scaling and XWayland: X11 apps render at scale 1 and are upscaled. Defaults:
`xwayland.force_zero_scaling = false`, `xwayland.use_nearest_neighbor = true` (upscaled X11 apps
look pixelated rather than blurry). Setting `force_zero_scaling = true` renders them at native
resolution but tiny unless the app scales itself (e.g. Steam, some games). Decide per app; the
main X11 holdouts on this machine are likely Steam and games. [V: wiki `config-options.md` Xwayland, 2026-10-29]

### Color: 10-bit and wide gamut

- ProArt panels are typically true 10-bit (or 8-bit+FRC) and wide gamut. `bitdepth = 10` with
  `cm = "auto"` (srgb for 8 bpc, wide for 10 bpc) is the wiki's recommendation. [V: `monitors/colors.md`]
- Caveats from the wiki [V]: border and other Hyprland-drawn colors are not 10-bit; **some apps
  can't screen-capture with 10-bit enabled**; 8-bit+FRC panels advertising 10-bit can cause eye strain.
- An ICC profile (`icc = "/abs/path.icm"`) overrides `cm` and forces sRGB EOTF. Relevant for
  color-managed Blender work. Not part of the installer; documented as an option.
- **12-bit is not available**: `bitdepth` takes 8 or 10 [V: wiki `monitors/colors.md`, 2026-10-30].
  The link is not the limit: 4K60 RGB at 12 bpc needs ~18.7 Gbit/s, within DP 1.4 HBR3's
  25.92 Gbit/s payload [arithmetic, approx.]. Hyprland's option range is.
- Presets [V wiki]: `auto` (srgb at 8 bpc, **wide = BT.2020 primaries** at 10 bpc), `srgb`, `dcip3`,
  `dp3`, `adobe`, `wide`, `edid` ("known to be inaccurate"), `hdr`, `hdredid`.
- **Configured (2026-10-30): `bitdepth = 10, cm = "srgb"`** (`config/hypr/conf/monitors.lua`).
  `auto` would pick BT.2020 primaries at 10 bpc, which no ProArt panel covers, so sRGB content would
  be mapped to the wrong primaries [inference from the preset table]. With `srgb`, set the panel's
  OSD to its sRGB mode, or switch `cm` to the preset matching the panel's native gamut (`dcip3` /
  `adobe`) once the model is known. Set `bitdepth = 8` if screen sharing breaks.

### KVM hot-unplug: what Hyprland 0.57 does

Read from the v0.57.0 source (`src/state/FallbackState.cpp`, `src/state/workspace/LifecyclePolicy.cpp`). [V: source, 2026-10-29]

1. **Last real monitor disappears** → Hyprland creates a headless output named `FALLBACK` and
   moves workspaces onto it. Apps keep running; nothing is killed.
2. Before moving, it **records each workspace's original monitor** (`m_returnMonitors`) and
   each monitor's active workspace (`m_rememberedActiveWorkspaces`).
3. **A real monitor returns** → `FALLBACK` is destroyed; every workspace whose recorded home is
   that monitor moves back, and the remembered active workspace is re-activated.
4. If monitors come back one at a time, orphaned workspaces go to the first one, then the
   second monitor's workspaces return to it when it appears.

Key limitation: the memory is keyed by **connector name** (`DP-1`, `DP-2`), not by description,
and lives only in memory. It works as long as the KVM keeps each panel on the same GPU
connector. If connector names change across a switch (some MST hubs/docks renumber), or
Hyprland restarts while switched away, workspaces won't go home automatically.

Planned mitigations:
- `hl.workspace_rule({ workspace = "1", monitor = "desc:...", default = true })` etc. so the
  config, not just runtime memory, says where workspaces live.
- A "send workspaces home" entry in the monitor menu (moves each bound workspace back to its
  monitor), for when automatic restoration fails.
- `hl.on("monitor.added", ...)` to re-apply wallpaper and refresh the bar. Events exist:
  `monitor.added`, `monitor.removed`, `monitor.layout_changed`. [V: wiki events.md]

Other components under hotplug:

| Component | Risk | Plan |
| --- | --- | --- |
| Floating windows | resized/moved while on the 1920×1080 `FALLBACK`; may return at odd positions | accept; the monitor menu offers "re-center floating windows" |
| hyprpaper | wallpaper set per monitor name; behavior on re-add [TODO-verify] | re-apply on `monitor.added` |
| Bar | waybar has a long history of hotplug issues [BK]; Quickshell creates per-screen instances dynamically [BK] | weighs toward Quickshell (decision O3) |
| hyprlock | session locked while monitors gone, then monitors return: lock surfaces must appear on new outputs [TODO-verify] | test on hardware before shipping |
| hypridle | unaffected (input-idle based) | none |
| Greeter (greetd + ReGreet in Hyprland) | same fallback/return logic as the desktop, since it is Hyprland | test a KVM switch at the login screen |

**This KVM:** Level1Techs states its DP 1.4 KVMs do not emulate monitors (the EDID engine exists for
HDCP re-keying) and recommends its DP 1.2 repeater where emulation is needed. [S: Level1Techs store
pages and forum threads via search, 2026-10-30] Each PC gets two separate DP links (no MST), so
connector names (`DP-1`, `DP-2`) stay stable across switches, which is what Hyprland's
return-workspaces-home logic keys on.

**Hardware alternative:** an EDID emulator keeps outputs "connected" while switched away, avoiding
every item above. Bandwidth check for a DP 1.2 repeater: HBR2 carries ~17.3 Gbit/s of payload; 4K60
needs ~12.5 Gbit/s at 8 bpc and ~15.6 Gbit/s at 10 bpc (RGB, reduced blanking) [arithmetic, approx.],
so it fits. Users report third-party DP 1.4 emulators failing to resync [S]. Software handling stays
the primary plan.

## AMD GPU

- Kernel driver `amdgpu` + Mesa (`mesa`, `vulkan-radeon`) from official repos; no environment
  variables needed for Hyprland (unlike NVIDIA). [BK]
- Monitoring for the bar: `amdgpu_top` or sysfs (`/sys/class/drm/card*/device/gpu_busy_percent`). [BK]

### ROCm / HIP for Blender

[S: archlinux.org blender package page and ArchWiki "Blender" via search, 2026-10-29]

- Arch `blender` (5.2.2 at time of search) lists **`hip-runtime-amd`** as the optional dependency
  for Cycles HIP rendering and **`hiprt`** for hardware ray tracing (RDNA2 / RX 6000 and newer).
- ArchWiki: GFX9, CDNA and RDNA GPUs supported; **HIP has known issues in the Cycles 3D
  viewport**, final renders (F12) work.
- **This GPU (Navi 21) is gfx1030**, which ROCm builds for natively; the
  `HSA_OVERRIDE_GFX_VERSION=10.3.0` workaround seen in guides is for gfx1031/1032 cards
  (RX 6700/6600), not this one. [S: several guides via search; BK] RDNA2 qualifies for
  hardware ray tracing through `hiprt`. 16 GB VRAM is ample for Cycles GPU rendering. Older reports of ROCm/Blender version mismatches crashing
  exist (ROCm 6.0 + Blender 4.0); current status unknown.
- ROCm userspace is large (several GB). Install it as an **opt-in installer step** ("Blender GPU
  rendering"), not in the core package set.
- `/dev/kfd` access normally requires membership in the `render` group [BK; TODO-verify on Arch].
  The installer step adds the user and says a re-login is needed.
- Verify: `rocminfo | grep -i gfx` lists the GPU; Blender → Preferences → System → Cycles Render
  Devices → HIP shows it.

## Login: greetd + ReGreet

Files (2026-10-30): `config/greetd/{config.toml,hyprland.lua,regreet.toml}`,
`themes/<palette>/greetd/regreet.css` (generated), installed by `install.sh` into `/etc/greetd/`
with `colors.lua`, the user's `monitors.lua` and `background.png` (the still ASCII sky,
`assets/sky/still-3840x2160.svg` rendered with `rsvg-convert`). regreet.toml keys checked against
ReGreet 0.5.0's `regreet.sample.toml` [V]; the CSS selectors (`frame`, `entry`, `button`,
`.suggested-action`) are generic GTK4 node names, **not checked against ReGreet's widget tree**
[TODO-verify on hardware with `GTK_DEBUG=interactive`]. `/var/lib/regreet` and `/var/log/regreet`
are created owned by `greeter` (README: needed for state and logs).


[V: ReGreet README @ 2026-10-29 (rharish101/ReGreet)] [S: Arch `extra` has `greetd` 0.10.3 and `greetd-regreet` 0.5.0]

How it fits together:

```text
greetd (system service, runs as root)
└── default_session, as user "greeter":
    dbus-run-session start-hyprland -- -c /etc/greetd/hyprland.lua
        └── hyprland.lua: monitors (same desc: rules, scale 1.5), no binds except VT switch,
            then exec "regreet; hyprctl dispatch 'hl.dsp.exit()'"
                └── ReGreet (GTK4): /etc/greetd/regreet.toml + /etc/greetd/regreet.css
```

- `/etc/greetd/config.toml` `[default_session]`: `command = "dbus-run-session start-hyprland -- -c /etc/greetd/hyprland.lua"`, `user = "greeter"`. [V: README]
- Upstream's Lua greeter config sets `misc.disable_hyprland_logo`, `disable_splash_rendering`,
  `disable_hyprland_guiutils_check` and starts ReGreet from `hl.on("hyprland.start", ...)`. [V: README]
- **Shared monitor config:** the installer copies the user's `monitors.lua` to
  `/etc/greetd/monitors.lua` (the greeter user cannot read `~/.config`), so the login screen has the
  same layout and scale. Re-run when monitors change.
- **ReGreet is single-monitor:** it draws on one output; the other shows the greeter
  Hyprland's background. Set that background to the generated wallpaper so both screens look intentional.
- Theming: `regreet.toml` (`[background] path/fit`, `[GTK] application_prefer_dark_theme,
  font_name, icon_theme_name, cursor_theme_name`, clock widget, greeting) and `regreet.css`
  (GTK4 CSS) — both generated from the palette. Key names are from the README on `master`;
  check them against the 0.5.0 package's `regreet.sample.toml` [TODO-verify].
- Background formats depend on the build (README mentions Glycin and GStreamer); a PNG from
  `rsvg-convert` is the safe choice.
- Enabling it is a system change: `sudo systemctl enable greetd.service` (and disabling any
  other display manager). The installer prompts.
- No `xorg-server` needed. Keyring auto-unlock: greetd ships a PAM file; whether it includes
  `pam_gnome_keyring` on Arch: [TODO-verify].

### Why not the alternatives

| Option | Verdict |
| --- | --- |
| SDDM | default greeter needs `xorg-server`; Wayland greeter still experimental; QML theming is a separate project |
| greetd + ReGreet under `cage` | simpler compositor, but no per-monitor scale/position by EDID description; hotplug handled by cage, not our config |
| greetd + tuigreet / ly | text-mode greeters: robust and fast, but limited theming; viable fallback if ReGreet misbehaves |
| GDM / plasma-login-manager | pull in large parts of GNOME / Plasma |
