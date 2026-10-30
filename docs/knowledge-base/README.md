# Knowledge base

Reference notes for building and maintaining this rice. Written for both humans and
Claude sessions working on the repo. The goal is to record what is actually true for
the versions we target, where it was verified, and what is still assumption.

## Verification labels

Every non-trivial claim carries one of these labels. Keep them accurate when editing.

| Label | Meaning |
| --- | --- |
| **[V: source, date]** | Verified against a primary source (upstream source code, upstream wiki repo, official release notes) on that date. |
| **[S: source, date]** | Secondary source only (news site, forum, search summary). Plausible, not confirmed. |
| **[BK]** | Background knowledge, not re-verified for this project. Treat as likely but check before depending on it. |
| **[TODO-verify]** | Known uncertainty that must be resolved on a real Arch install or in an `archlinux` container before shipping code that depends on it. |

## Pages

| Page | Covers |
| --- | --- |
| [hyprland.md](hyprland.md) | Hyprland 0.57: Lua-only config, API surface, binds, rules, hyprctl, pitfalls. **Read this first.** |
| [hypr-ecosystem.md](hypr-ecosystem.md) | hyprlock, hypridle, hyprpaper, hyprtoolkit, hyprlauncher, hyprpolkitagent, XDPH. These still use hyprlang `.conf`. |
| [arch-install.md](arch-install.md) | Vanilla Arch assumptions, package strategy, session startup, installer design constraints. |
| [hardware.md](hardware.md) | The owner's machine: dual 4K ProArt via KVM (hot-unplug behavior from Hyprland source), Navi 21 + ROCm/HIP, greetd + ReGreet login. |
| [launcher.md](launcher.md) | rofi 2.x on Wayland: layer-surface facts, rasi capabilities and limits, menu layout. |
| [kitty.md](kitty.md) | Kitty config keys relevant to theming, reload behavior, Hyprland interplay. |
| [zsh.md](zsh.md) | Zsh setup without a framework, plugin sourcing on Arch, prompt, ANSI-color dependencies. |
| [theming.md](theming.md) | How one palette reaches every app: Hyprland, kitty, zsh, GTK, Qt, cursors, fonts. |
| [sources.md](sources.md) | Source list with retrieval dates and how to re-verify. |

## Ground rules for this knowledge base

1. **Hyprland moves fast; this repo targets a specific version.** Any statement about
   Hyprland config syntax is tied to a version. When the target version changes, re-verify
   [hyprland.md](hyprland.md) against the upstream wiki at that tag before editing configs.
2. **Most Hyprland material on the internet is now wrong for us.** Anything written before
   May 2026 (blogs, Reddit, other people's dotfiles, most LLM training data) uses the hyprlang
   `hyprland.conf` syntax, which 0.57 no longer loads. Do not copy from it.
3. **Prefer primary sources.** The Hyprland wiki is a git repo (`hyprwm/hyprland-wiki`) and
   can be cloned even when `wiki.hypr.land` is unreachable. Upstream source trees are the
   final authority on option names and CLI flags.
4. **Record dates.** "Current" means nothing six months later.
