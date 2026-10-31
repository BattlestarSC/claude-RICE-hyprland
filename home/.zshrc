# rice: interactive zsh. Behavior lives in ~/.config/zsh/*.zsh (installed by the rice);
# your own additions go in ~/.config/zsh/local.zsh, which the installer never touches.
#
# Order matters: theme before the plugins (plugins keep pre-set styles), completion before the
# plugins that wrap Tab, local.zsh before late.zsh (syntax highlighting must be the last
# plugin, with history-substring-search right after it, as both projects require).
ZCONF="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
for _rice_module in session options history theme completion keybinds aliases plugins prompt local late; do
    [[ -r "$ZCONF/$_rice_module.zsh" ]] && source "$ZCONF/$_rice_module.zsh"
done
unset _rice_module
