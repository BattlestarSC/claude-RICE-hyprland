# CLI tools: htop, btop, fastfetch

First round of CLI tools (owner, 2026-10-30; D28). Labels as in [README.md](README.md#verification-labels).
Sources read 2026-10-30.

| Tool | Files deployed | Colors |
| --- | --- | --- |
| htop 3.5 | `~/.config/htop/htoprc` (from `config/htop/htoprc`) | terminal ANSI colors (kitty/foot theme) |
| btop 1.4.8 | `~/.config/btop/btop.conf`, `~/.config/btop/themes/rice.theme` (generated) | palette, 24-bit |
| fastfetch 2.70.0 | `~/.config/fastfetch/config.jsonc` (generated) | palette, 24-bit |

## htop

- Config path: `$XDG_CONFIG_HOME/htop/htoprc`, else `~/.config/htop/htoprc` [V: htop 3.5.3 `Settings.c`
  `Settings_new`].
- **htop cannot load custom colors.** `color_scheme` picks one of its built-in schemes (0 Default
  … 7 Nord, `CRT.h`). Scheme 0 draws with the terminal's 16 ANSI colors, which kitty and foot take
  from the palette, so it matches without a theme file.
- A partial `htoprc` is valid: keys not set (meters, columns, screens) fall back to htop's
  defaults (`Settings_read` calls `Settings_defaultMeters`/`Settings_defaultScreens` when none
  were read) [V]. Unknown keys are ignored silently, so the names are checked by
  `tests/cli/check_cli.py` against the `String_eq(option[0], …)` list in `Settings.c`.
- htop rewrites the file with every option when it exits, keeping these values.
- Set: mouse, screen tabs (Main / I/O), highlighted program base names, megabytes and threads,
  userland threads hidden, CPU frequency and temperature (temperature needs `lm_sensors`), CPUs
  counted from 1, 1.5 s refresh.
- Rendered on htop 3.3 (Ubuntu) in a pty: the file loads, the meters use ANSI colors.

## btop

- Config `~/.config/btop/btop.conf`; user themes in `~/.config/btop/themes/` (`Config::conf_dir /
  "themes"`); `color_theme = "rice"` matches a theme file by full path, file name **or stem**
  [V: btop v1.4.8 `src/btop.cpp`, `src/btop_theme.cpp` `setTheme`].
- Theme format: `theme[key]="#RRGGBB"`. The 48 keys are btop's `Default_theme` table; every one is
  set (`tests/cli/check_cli.py` fails on an unknown or missing key) [V].
- Config parsing: the first line must be a comment (btop reads it as the version line), then
  `name = value`; booleans are `True`/`False`; unknown names are skipped [V: `Config::load`].
  btop rewrites the file on exit with all options, keeping these values.
- Mapping: box outlines one accent each (CPU blue, memory green, network purple, processes
  pink), temperature green → yellow → red, CPU graph cyan → blue → purple, memory meters from
  `surface2` to the accent, selection `surface2` with `bright` text.
- Set: theme, truecolor, rounded corners, braille graphs, vim keys (`h j k l g G`), 1.5 s update,
  24-hour clock, battery if present.
- GPU box: btop shows AMD GPUs through ROCm SMI when the library is installed [BK]; press `5`
  (gpu0) to toggle it. Not added to `shown_boxes` so a machine without it shows no empty box.
- Rendered on btop 1.3.0 (Ubuntu) in a pty with 24-bit color: every color on screen is a palette
  color; the rewritten `btop.conf` kept the rice values.

## fastfetch

- Config `~/.config/fastfetch/config.jsonc` (JSONC: comments allowed) [BK path; standard].
- Colors accept `#RRGGBB` (converted to 24-bit SGR) besides names and ANSI codes [V: fastfetch
  2.70.0 `src/common/impl/option.c` `ffOptionParseColorNoClear`].
- Validated against the release's own `doc/json_schema.json` (draft-07) by
  `tests/cli/check_cli.py` (needs the `jsonschema` Python package); a wrong key or value fails.
- Layout: built-in Arch logo in purple/blue; title (user pink, host purple); groups separated by
  `break`: system (blue keys: OS, kernel, uptime, packages), desktop (purple: WM, terminal, shell,
  font, cursor), hardware (cyan: CPU and GPU with temperature, memory, disks, displays), then the
  color blocks. Keys carry Nerd Font icons (kitty maps them to Symbols Nerd Font Mono).
- **Not run** in the build environment (no fastfetch package for its Ubuntu); schema-checked only.

## Tests

```sh
python3 tests/cli/check_cli.py <htop 3.5.3> <btop v1.4.8> <fastfetch 2.70.0>   # checkouts; see docstring
```
