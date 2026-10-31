# shellcheck shell=bash
# Exact versions of what the installer builds or downloads on systems whose packages are too old
# or missing (lib/extras.sh). Sourced by install.sh. Docs: docs/knowledge-base/platforms.md.
#
# The Hyprland stack is pinned to the commits Hyprland v0.57.0's own flake.lock uses, so the
# libraries match the compositor exactly; the apps around it to their latest releases
# (2026-10-30). Update all together.

# name|repository|commit or tag|build system|extra configure arguments
# shellcheck disable=SC2034  # used by lib/extras.sh
declare -ga HYPR_STACK=(
    "hyprwayland-scanner|https://github.com/hyprwm/hyprwayland-scanner|62e62c1ca23da17612c6890d4ad2064f575643db|cmake|"
    "hyprutils|https://github.com/hyprwm/hyprutils|0d13d5a624eb093b600d1b2cbe448fb613c86424|cmake|"
    "hyprlang|https://github.com/hyprwm/hyprlang|9508458be316a0d70d37ebed1ab725ccd10411ff|cmake|"
    "hyprcursor|https://github.com/hyprwm/hyprcursor|e4ed7c08123df5af460a0a70961380cbfb872f76|cmake|"
    "hyprgraphics|https://github.com/hyprwm/hyprgraphics|80c7d00f2236732853e390019ff8d79d17fa3612|cmake|"
    "aquamarine|https://github.com/hyprwm/aquamarine|52ea11f06dd492f34b3cc0b39a9c805beecafcff|cmake|"
    "hyprland-protocols|https://github.com/hyprwm/hyprland-protocols|044a434ec371f985655389bcef09286b1af3d77c|cmake|"
    "hyprwire|https://github.com/hyprwm/hyprwire|a546e42d45e161682f729ebf52375bd4800d7041|cmake|"
    "hyprland|https://github.com/hyprwm/Hyprland|v0.57.0|cmake|"
    "hyprtoolkit|https://github.com/hyprwm/hyprtoolkit|2907e0d1f8a3a540737a0e738acc40d48ad7ba0d|cmake|"
    "hyprland-guiutils|https://github.com/hyprwm/hyprland-guiutils|204f39d6c7a4aca7042587d4638e19cdeccf63bc|cmake|"
    "xdg-desktop-portal-hyprland|https://github.com/hyprwm/xdg-desktop-portal-hyprland|0121b2e3f85c7ebf6280173f1054f7e5606262d1|cmake|"
    "hyprlock|https://github.com/hyprwm/hyprlock|v0.9.6|cmake|"
    "hypridle|https://github.com/hyprwm/hypridle|v0.1.8|cmake|"
    "hyprpolkitagent|https://github.com/hyprwm/hyprpolkitagent|v0.2.0|cmake|"
    "hyprshutdown|https://github.com/hyprwm/hyprshutdown|v0.1.1|cmake|"
)

# Built only where the packaged version is older than Hyprland 0.57 requires (>= 1.49). Its newer
# XML fails wayland-scanner 1.24's --strict validation, so a current scanner comes first (the
# scanner alone: the system's libwayland stays). Latest tags 2026-10-30 (tests/platforms/tags.sh).
# shellcheck disable=SC2034
declare -g WAYLAND_SCANNER_PIN="wayland-scanner|https://gitlab.freedesktop.org/wayland/wayland.git|1.26.0|meson|-Dlibraries=false -Dscanner=true -Ddocumentation=false -Dtests=false"
# shellcheck disable=SC2034
declare -g WAYLAND_PROTOCOLS_PIN="wayland-protocols|https://gitlab.freedesktop.org/wayland/wayland-protocols.git|1.50|meson|-Dtests=false"
# shellcheck disable=SC2034
declare -g QUICKSHELL_PIN="quickshell|https://github.com/quickshell-mirror/quickshell|v0.3.2|cmake|-DCRASH_HANDLER=OFF -DDISTRIBUTOR=rice-installer"
# shellcheck disable=SC2034
declare -g REGREET_PIN="regreet|https://github.com/rharish101/ReGreet|0.5.0|cargo|"
# shellcheck disable=SC2034
declare -g ZSH_HSS_PIN="zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search|v1.1.0|copy|"
# Capitaine ships SVG sources only; lib/extras.sh renders them (rsvg-convert + xcursorgen).
# shellcheck disable=SC2034
declare -g CAPITAINE_PIN="capitaine-cursors|https://github.com/keeferrourke/capitaine-cursors|r4|cursors|"

# Upstream release files: url|sha256 (computed 2026-10-30 from the downloads).
# shellcheck disable=SC2034
declare -g NEOVIM_URL="https://github.com/neovim/neovim/releases/download/v0.12.3/nvim-linux-x86_64.tar.gz|c441b547142860bf01bcce39e36cbed185c41112813e15443b16e5237750724d"
# shellcheck disable=SC2034
declare -g TREESITTER_URL="https://github.com/tree-sitter/tree-sitter/releases/download/v0.27.1/tree-sitter-linux-x64.gz|d01042f94ba3d6827ddc9788e235f75d8366431be42bdf90ade534d960c98b7d"
# shellcheck disable=SC2034
declare -g NERD_SYMBOLS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.tar.xz|01172f37db8543edb102e5cb5c64101c9f4686630804d49b419aa07b23a69996"
# shellcheck disable=SC2034
declare -g ADW_GTK3_URL="https://github.com/lassekongo83/adw-gtk3/releases/download/v6.5/adw-gtk3v6.5.tar.xz|a81780fadfc432be0fc3d89c4ebb41aa28e4f032d42c36f9789c57dd10cfa41c"
