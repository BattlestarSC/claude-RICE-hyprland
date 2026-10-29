# Color scheme proposals

**Status: awaiting selection.** Pick one (or ask for a blend) and it becomes `colors/<name>.toml`,
the single source of truth for every generated app theme.

- Visual comparison: open [`preview.html`](preview.html) in a browser (desktop mockups, swatches,
  contrast numbers, copy-ready kitty colors). Regenerate with
  `python3 tools/preview.py --standalone colors/proposals/*.toml > docs/colors/preview.html`.
- Validate: `python3 tools/palette.py check colors/proposals/*.toml` (all four pass today).

## Brief

"Soft dark mode": comfortable for long sessions, readable, no glare. Monokai-like accents, space
theme, decent contrast.

Translated into measurable requirements:

| Requirement | Rule (WCAG 2.x contrast vs. the palette's `base`) | Rationale |
| --- | --- | --- |
| Not blinding | background is never pure black; body text **11–15.5:1** | 21:1 white-on-black causes halation (glowing text edges), worst for astigmatic eyes. Most comfortable dark themes sit at 11–15. |
| Readable | secondary text ≥ 7:1 (AAA) | |
| Comments readable | comments / ANSI 8 ≥ 4.5:1 (AA) | Classic Monokai's comment `#75715E` on `#272822` is **3.0:1**, below AA. zsh-autosuggestions also renders in ANSI 8. |
| Accents readable as text | every accent ≥ 6:1, bright variants ≥ 7:1 | Classic Monokai pink `#F92672` on `#272822` is **3.9:1**: punchy but fails AA. |
| Selection usable | text on `surface1` ≥ 9:1, accents on `surface1` ≥ 4.5:1 | Code stays readable when highlighted. |
| Borders visible | `surface2` vs `base` ≥ 1.4:1 | Inactive window borders, separators. |
| Space theme | blue-violet hue bias in all neutrals; starfield/nebula-hued border gradients | The theme lives in hue, not in decoration that costs readability. |

## Shared design across all proposals

### Roles

| Role | Used for |
| --- | --- |
| `crust` | bar background, outermost chrome, dark text on accent pills |
| `mantle` | secondary panels, inactive tabs, notification background |
| `base` | terminal and editor background (all contrast is measured here) |
| `surface0` | cursorline, hover |
| `surface1` | selection, inactive window border, ANSI 0 |
| `surface2` | separators, kitty inactive border |
| `overlay` | comments, disabled text, autosuggestions (ANSI 8) |
| `subtext` | secondary text (ANSI 7) |
| `text` | body text |
| `bright` | headings, emphasis (ANSI 15) |
| 8 accents | red, orange, yellow, green, cyan, blue, purple, pink, plus a bright variant of each |

### Syntax mapping (Monokai-derived)

| Token | Color | Monokai origin |
| --- | --- | --- |
| keyword, storage, operator | red | Monokai pink `#F92672` |
| function name / call | green | `#A6E22E` |
| string | yellow | `#E6DB74` |
| number, constant, boolean | purple | `#AE81FF` |
| builtin, type, library | cyan | `#66D9EF` |
| parameter, table field | orange | `#FD971F` |
| comment | overlay, italic | `#75715E` |
| URL, link | blue | (Monokai has no blue) |
| escape, regex, special | pink | |

### ANSI mapping

| Index | Role | Index | Role |
| --- | --- | --- | --- |
| 0 black | `surface1` | 8 bright black | `overlay` |
| 1 red | red | 9 | red (bright) |
| 2 green | green | 10 | green (bright) |
| 3 yellow | yellow | 11 | yellow (bright) |
| 4 blue | blue | 12 | blue (bright) |
| 5 magenta | purple | 13 | purple (bright) |
| 6 cyan | cyan | 14 | cyan (bright) |
| 7 white | `subtext` | 15 bright white | `bright` |

Orange and pink have no ANSI slot; apps that support truecolor get them by hex.

## The four proposals

### 1. Nebula (recommended)

Monokai Pro's accent set, slightly desaturated, on a violet-tinted deep-space base (`#1C1B26`).
Window border gradient cyan → purple.

- **Pros:** closest to the brief as written. Monokai character intact, background visibly
  "space" without being navy. Text at 13.2:1 sits mid-range of the comfort band.
- **Cons:** red is the weakest accent (6.4:1); keywords are the most frequent token, so red
  carries a lot of weight. If it feels dim, nudge it toward `#FF7A93`.

### 2. Deep Field

Cool navy-black (`#131727`), cooler green and cyan, highest contrast of the set (text 14.4:1,
all accents ≥ 7:1). Border gradient blue → cyan; yellow cursor.

- **Pros:** best on low-quality or high-glare panels, and at small font sizes. Strongest "space"
  read.
- **Cons:** navy bases drift toward Tokyo Night / Nord territory; less Monokai-like. More blue
  light. Slightly harsher in a dark room.

### 3. Event Horizon

Warm graphite with a faint violet bias (`#212026`), desaturated accents, lowest contrast that
still passes every rule (text 11.5:1).

- **Pros:** the "softest" option. Lowest glare; suits dim rooms and long sessions.
- **Cons:** accents are muted enough that diffs and error states stand out less. On a cheap
  panel or in daylight it can look washed out. Least "space".

### 4. Pulsar

Near-black (`#16151D`) with near-original Monokai accent saturation (orange `#FD971F`, green
`#A6E22E`, cyan `#66D9EF`, purple `#AE81FF` unchanged; pink lightened for contrast).

- **Pros:** the most recognizably Monokai. Punchy, high energy.
- **Cons:** least "soft". Fully saturated green and orange on near-black vibrate for some
  people over long sessions. Text at 15.4:1 is at the top of the allowed band.

## Side-by-side

Numbers after each hex are contrast against that palette's `base` (the darkest five roles are
backgrounds; their contrast is omitted).

| role | Nebula | Deep Field | Event Horizon | Pulsar |
| --- | --- | --- | --- | --- |
| crust | `#121119` | `#0A0D18` | `#17161B` | `#0C0B11` |
| mantle | `#17161F` | `#0E1220` | `#1C1B21` | `#110F17` |
| base | `#1C1B26` | `#131727` | `#212026` | `#16151D` |
| surface0 | `#252433` | `#1B2036` | `#2A2930` | `#201E2A` |
| surface1 | `#302E42` | `#262C47` | `#323139` | `#2A2837` |
| surface2 | `#423F59` 1.7 | `#38405F` 1.8 | `#47454F` 1.7 | `#3C3950` 1.6 |
| overlay | `#8A86A6` 4.9 | `#8189AC` 5.2 | `#8E8A98` 4.8 | `#85819C` 4.8 |
| subtext | `#B8B4CC` 8.5 | `#B2BAD8` 9.2 | `#B8B4C0` 7.9 | `#BDB9CD` 9.5 |
| text | `#E4E1EE` 13.2 | `#E2E7F5` 14.4 | `#DCD8E1` 11.5 | `#EEEBF4` 15.4 |
| bright | `#F4F2F9` 15.3 | `#F4F6FC` 16.5 | `#ECE9F0` 13.5 | `#FBFAFD` 17.4 |
| red | `#FF6E8A` 6.4 | `#FF7891` 7.1 | `#EC8597` 6.4 | `#FF5E95` 6.3 |
| orange | `#FA9D6B` 8.2 | `#FFA46E` 9.1 | `#E6A684` 7.8 | `#FD971F` 8.3 |
| yellow | `#F2D57E` 11.8 | `#F5D67B` 12.5 | `#E0CD90` 10.2 | `#E6DB74` 12.7 |
| green | `#A9DC7A` 10.7 | `#8EDB95` 10.8 | `#AACC90` 9.0 | `#A6E22E` 11.7 |
| cyan | `#7FD7E6` 10.3 | `#6FD9E4` 10.8 | `#8DC9D2` 8.8 | `#66D9EF` 11.0 |
| blue | `#86ACFF` 7.6 | `#7DABFF` 7.7 | `#98B0E4` 7.4 | `#6FA3FF` 7.2 |
| purple | `#B79CF7` 7.4 | `#A99CFF` 7.5 | `#B8A6E0` 7.4 | `#AE81FF` 6.4 |
| pink | `#F590CF` 7.9 | `#F28FCB` 8.1 | `#DE9EC6` 7.6 | `#FF6AC1` 7.0 |
| red (bright) | `#FF8DA3` 7.8 | `#FF97AA` 8.7 | `#F2A0AE` 8.0 | `#FF7AA6` 7.4 |
| orange (bright) | `#FFB38A` 9.8 | `#FFBA90` 10.7 | `#EDBBA0` 9.4 | `#FFAE52` 9.9 |
| yellow (bright) | `#F8E3A2` 13.4 | `#F9E4A3` 14.1 | `#E9DBAD` 11.7 | `#EEE59A` 14.1 |
| green (bright) | `#BFE899` 12.3 | `#ABE6B0` 12.4 | `#BFD9AB` 10.6 | `#BCEB63` 13.1 |
| cyan (bright) | `#A0E4EF` 12.0 | `#97E5EC` 12.5 | `#A9D7DE` 10.4 | `#8DE3F3` 12.4 |
| blue (bright) | `#A5C1FF` 9.5 | `#A0C2FF` 9.9 | `#B1C3EB` 9.1 | `#96BBFF` 9.4 |
| purple (bright) | `#CAB6FA` 9.4 | `#C1B7FF` 9.7 | `#CBBDE9` 9.2 | `#C4A3FF` 8.7 |
| pink (bright) | `#F8AEDC` 9.8 | `#F6AED9` 10.2 | `#E7B7D5` 9.3 | `#FF8FD0` 8.7 |

## Choosing

| If you value most… | Pick |
| --- | --- |
| Monokai feel + comfort, balanced | **Nebula** |
| Legibility on any screen, strongest space mood | Deep Field |
| Minimum eye strain, dim rooms | Event Horizon |
| Original Monokai punch | Pulsar |

Blends are cheap: e.g. Nebula's base ramp with Deep Field's accents, or Nebula with Event
Horizon's softer red/orange. Every change re-runs through `tools/palette.py check`.
