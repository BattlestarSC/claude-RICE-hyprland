# Plugins from Arch packages (no framework, no downloads). A missing package just means that
# plugin is off. Paths: docs/knowledge-base/zsh.md#packages-and-plugin-paths.
_rice_source() {
    local f
    for f in "$@"; do
        [[ -r "$f" ]] && { source "$f"; return 0; }
    done
    return 1
}

# Fish-style suggestions from history (then completion) as grey text; Right/End accepts,
# Alt+Right accepts one word.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
_rice_source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# fzf: Ctrl+R history, Ctrl+T files, Alt+C cd; `**<Tab>` fuzzy completion. Plain Tab keeps the
# menu selector above (fzf hands it on when there is no ** trigger).
(( $+commands[fzf] )) && source <(fzf --zsh)

# zoxide: `z partial-name` jumps to frequent directories.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
