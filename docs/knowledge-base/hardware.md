# Target hardware: dual 4K via KVM, AMD GPU, ROCm

The owner's machine. The rice must work well here first; other hardware is best-effort.

| Component | Detail | Still unknown |
| --- | --- | --- |
| Displays | 2 × ASUS ProArt 27" 4K | exact model (10-bit? wide gamut? refresh?) |
| Connection | through a KVM; **outputs disappear when the KVM switches away** | KVM model; DP or HDMI; any MST hub |
| GPU | AMD | model (decides ROCm/HIP support and HIP RT) |
| Compute | HIP / ROCm for Blender Cycles | |
| Login | SDDM (graphical) | |

## Displays

### Identify by description, not by port

`hl.monitor({ output = "desc:..." })` matches the EDID description, which includes the serial
number, so two identical ProArt panels stay distinguishable and keep their position even if
cables are swapped between GPU ports. [V: hyprland-wiki `monitors/output-selection.md`, `_index.md`, 2026-10-29]

```lua
-- Real strings come from `hyprctl monitors all` on the machine; the installer will offer to capture them.
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
- Default plan: `bitdepth = 10, cm = "auto"` behind a toggle in the monitor menu, since screen
  sharing is the main thing it can break. Decide after the exact model is known.

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
| SDDM (X11 greeter) | X server handles hotplug via RandR; greeter may not re-layout [BK] | acceptable at login |

**Hardware alternative:** a KVM with EDID emulation (or DP EDID-emulator dongles) keeps outputs
"connected" while switched away, which avoids every item above. Worth knowing if the software
mitigations prove flaky.

## AMD GPU

- Kernel driver `amdgpu` + Mesa (`mesa`, `vulkan-radeon`) from official repos; no environment
  variables needed for Hyprland (unlike NVIDIA). [BK]
- Monitoring for the bar: `amdgpu_top` or sysfs (`/sys/class/drm/card*/device/gpu_busy_percent`). [BK]

### ROCm / HIP for Blender

[S: archlinux.org blender package page and ArchWiki "Blender" via search, 2026-10-29]

- Arch `blender` (5.2.2 at time of search) lists **`hip-runtime-amd`** as the optional dependency
  for Cycles HIP rendering and **`hiprt`** for hardware ray tracing (RDNA2 / RX 6000 and newer).
- ArchWiki: GFX9, CDNA and RDNA GPUs supported; **HIP has known issues in the Cycles 3D
  viewport**, final renders (F12) work. Older reports of ROCm/Blender version mismatches crashing
  exist (ROCm 6.0 + Blender 4.0); current status unknown.
- ROCm userspace is large (several GB). Install it as an **opt-in installer step** ("Blender GPU
  rendering"), not in the core package set.
- `/dev/kfd` access normally requires membership in the `render` group [BK; TODO-verify on Arch].
  The installer step adds the user and says a re-login is needed.
- Verify: `rocminfo | grep -i gfx` lists the GPU; Blender → Preferences → System → Cycles Render
  Devices → HIP shows it.

## SDDM

[V: sddm source `src/common/Configuration.h`, ChangeLog @ 2026-10-20] [V: Hyprland `example/hyprland.desktop.in`]

- Hyprland installs a session file whose `Exec` is `start-hyprland`; SDDM lists it automatically.
- SDDM's greeter runs on **X11 by default** (`[General] DisplayServer=x11`), which means
  `xorg-server` must be installed even though the desktop is Wayland.
- A Wayland greeter exists (`DisplayServer=wayland`, `[Wayland] CompositorCommand`, default
  `weston --shell=kiosk`), still labelled **experimental** in the 0.20/0.21 changelogs, and
  keyboard layout switching is not implemented there.
- HiDPI: `EnableHiDPI=true` is the default for both greeters. At 4K/27" verify the greeter is
  readable; if not, set `GreeterEnvironment=QT_SCREEN_SCALE_FACTORS=1.5` (X11) [BK].
- Themes are QML; SDDM 0.21 lets a theme declare its Qt version. A space-themed SDDM theme in
  the palette is its own sub-project (Phase 3).
- Enabling it is a system change: `sudo systemctl enable sddm.service`. The installer prompts.
- Display managers usually ship PAM config that unlocks GNOME Keyring at login, so the TTY PAM
  edit from [arch-install.md](arch-install.md#starting-the-session) is not needed. [V: wiki uwsm.md note]

Plan: X11 greeter in v1 (most tested path), Wayland greeter via weston as a documented option.
