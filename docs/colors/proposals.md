# Color scheme proposals

**Status: decided — Quasar** (owner, 2026-10-29; D10 in [decisions.md](../decisions.md)).
The blend dial stays available for fine-tuning.

- Visual comparison + live blend dial: open [`preview.html`](preview.html) in a browser.
- Validate: `python3 tools/palette.py check colors/proposals/round2/*.toml`
- Regenerate the page: `python3 tools/preview.py --standalone colors/proposals/round2/*.toml colors/proposals/round1/*.toml > docs/colors/preview.html`

## History

| Round | Outcome |
| --- | --- |
| 1 (2026-10-29) | Four palettes: Nebula, Deep Field, Event Horizon, Pulsar ([round1/](../../colors/proposals/round1/)). Owner: "somewhere between Pulsar and Event Horizon; Event Horizon is more readable, Pulsar more comfortable; worried about Pulsar's readability." |
| 2 (2026-10-29) | Added APCA to the rules (below), built `tools/blend.py`, proposed **Quasar** and the dial. Owner accepted Quasar. |

## Why the feedback contradicted the round-1 numbers, and what changed

Round 1 used only WCAG 2 contrast ratios, which rank Pulsar as *more* readable (text 15.4:1 vs
11.5:1). The perception was the reverse. Two effects that WCAG 2 doesn't model explain it:

1. **Halation.** Very bright text on a very dark background glows and smears, worst for
   astigmatic eyes. APCA puts Pulsar's body text at Lc 95, past the comfortable range;
   Event Horizon sits at Lc 82.
2. **Uneven accent lightness.** Pulsar's accents span Lc 47 (red, purple) to Lc 82 (yellow):
   yellow strings shout, red keywords recede, and the eye has to keep re-adapting. Event
   Horizon's spread is 24; Quasar's is 16.

Pulsar's *comfort* comes from its darker background: less total light from two 4K panels.
Quasar keeps that and fixes the other two:

| Group | Quasar takes | Effect |
| --- | --- | --- |
| Background ramp | 30% toward Event Horizon | nearly as dark as Pulsar (`#191820` vs `#16151D`) |
| Text ramp | 55% toward Event Horizon | body text Lc 88: no halation, still crisp |
| Accents | 40% toward Event Horizon in chroma/hue, then lightness clamped to Lc 58–74 | Monokai hues and most of Pulsar's saturation, evenly bright |
| Comments | lifted to Lc 47 | comments are readable, not faint (classic Monokai comments are ~Lc 36) |

Trade-offs to check on your screens:
- **Red is lighter and pinker** (`#FD8DA8`) than Pulsar's `#FF5E95`: lifting it to Lc 58 at the
  same chroma moves it toward salmon. Red (keywords) and pink (escapes, specials) are closer
  than in Pulsar. If keywords feel weak, the fix is a more magenta pink rather than a darker red.
- **Yellow is dimmer** than Monokai's (`#DCCD77` vs `#E6DB74`): capped at Lc 74 so strings don't glare.
- **Comments are more visible** than in classic Monokai. Deliberate; easy to lower if they distract.

## Contrast rules

Measured against the palette's `base`. Enforced by `tools/palette.py check` (42 rules).

| Rule | WCAG 2 ratio | APCA Lc | Why |
| --- | --- | --- | --- |
| Body text | 11 – 15.5 | 75 – 92 | readable; upper bound prevents halation |
| Secondary text | ≥ 7 | ≥ 60 | |
| Comments / ANSI 8 / zsh autosuggestions | ≥ 4.5 | ≥ 45 | |
| Text on selection (`surface1`) | ≥ 9 | | |
| Inactive borders (`surface2`) | ≥ 1.4 | | |
| Each accent on base | ≥ 6 | 55 – 82 | |
| Accent spread (max − min) | | ≤ 18 | no token glares, none recedes |
| Accents inside a selection | ≥ 4.5 | | |
| Bright accents | ≥ 7 | | |
| Dark text on cyan pill | ≥ 7 | | |

APCA is the perceptual contrast model in the WCAG 3 drafts (APCA-W3 0.0.98G constants). It is
not yet a standard, so the WCAG 2 rules stay in force. `tools/palette.py` implements it and
checks it against the published reference values (`#888` on `#fff` = Lc 63.06).

## Quasar vs its endpoints

Cells: hex, WCAG ratio / APCA Lc on that palette's base.

| role | Quasar | Pulsar | Event Horizon |
| --- | --- | --- | --- |
| crust | `#0F0E14` | `#0C0B11` | `#17161B` |
| mantle | `#14131A` | `#110F17` | `#1C1B21` |
| base | `#191820` | `#16151D` | `#212026` |
| surface0 | `#23212C` | `#201E2A` | `#2A2930` |
| surface1 | `#2C2B38` | `#2A2837` | `#323139` |
| surface2 | `#3F3D50` | `#3C3950` | `#47454F` |
| overlay | `#9D99AD` 6.4 / 47 | `#85819C` 4.8 / 36 | `#8E8A98` 4.8 / 38 |
| subtext | `#BAB6C6` 8.9 / 63 | `#BDB9CD` 9.5 / 65 | `#B8B4C0` 7.9 / 61 |
| text | `#E4E0E9` 13.5 / 88 | `#EEEBF4` 15.4 / 95 | `#DCD8E1` 11.5 / 82 |
| bright | `#F3F1F6` 15.7 / 98 | `#FBFAFD` 17.4 / 104 | `#ECE9F0` 13.5 / 92 |
| red | `#FD8DA8` 8.0 / 58 | `#FF5E95` 6.3 / 47 | `#EC8597` 6.4 / 51 |
| orange | `#F69C56` 8.2 / 59 | `#FD971F` 8.3 / 59 | `#E6A684` 7.8 / 60 |
| yellow | `#DCCD77` 10.9 / 74 | `#E6DB74` 12.7 / 82 | `#E0CD90` 10.2 / 75 |
| green | `#A6DA64` 10.8 / 74 | `#A6E22E` 11.7 / 77 | `#AACC90` 9.0 / 67 |
| cyan | `#78D3E3` 10.2 / 71 | `#66D9EF` 11.0 / 74 | `#8DC9D2` 8.8 / 66 |
| blue | `#88AFFD` 8.0 / 58 | `#6FA3FF` 7.2 / 52 | `#98B0E4` 7.4 / 57 |
| purple | `#BEA0FE` 8.1 / 58 | `#AE81FF` 6.4 / 47 | `#B8A6E0` 7.4 / 57 |
| pink | `#FB89CD` 8.0 / 58 | `#FF6AC1` 7.0 / 51 | `#DE9EC6` 7.6 / 58 |
| red (bright) | `#FFA7BA` 9.6 / 67 | `#FF7AA6` 7.4 / 54 | `#F2A0AE` 8.0 / 61 |
| orange (bright) | `#FEB076` 9.8 / 68 | `#FFAE52` 9.9 / 67 | `#EDBBA0` 9.4 / 70 |
| yellow (bright) | `#EBDC85` 12.7 / 83 | `#EEE59A` 14.1 / 89 | `#E9DBAD` 11.7 / 83 |
| green (bright) | `#B5EA73` 12.6 / 83 | `#BCEB63` 13.1 / 84 | `#BFD9AB` 10.6 / 76 |
| cyan (bright) | `#87E3F3` 12.0 / 80 | `#8DE3F3` 12.4 / 81 | `#A9D7DE` 10.4 / 75 |
| blue (bright) | `#A0C0FD` 9.6 / 67 | `#96BBFF` 9.4 / 64 | `#B1C3EB` 9.1 / 68 |
| purple (bright) | `#CBB5FE` 9.7 / 68 | `#C4A3FF` 8.7 / 60 | `#CBBDE9` 9.2 / 69 |
| pink (bright) | `#FDA4D7` 9.6 / 67 | `#FF8FD0` 8.7 / 61 | `#E7B7D5` 9.3 / 69 |

## Shared design (all rounds)

### Roles

| Role | Used for |
| --- | --- |
| `crust` | bar background, outermost chrome, dark text on accent pills |
| `mantle` | secondary panels, inactive tabs, launcher body, notifications |
| `base` | terminal and editor background (all contrast is measured here) |
| `surface0` | cursorline, hover |
| `surface1` | selection, inactive window border, ANSI 0 |
| `surface2` | separators, kitty inactive border |
| `overlay` | comments, placeholders, generic names in the launcher, autosuggestions (ANSI 8) |
| `subtext` | secondary text (ANSI 7) |
| `text` | body text |
| `bright` | headings, emphasis, selected rows (ANSI 15) |
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

Orange and pink have no ANSI slot; truecolor apps get them by hex.

### Window border gradient

Quasar: red → purple (Monokai's signature pink-red into nebula violet). Round 1 palettes each
defined their own.
