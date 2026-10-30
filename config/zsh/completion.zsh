# Completion with a fish-style selector: Tab lists candidates in columns with descriptions and
# group headers; Tab again (or the arrows) moves a highlighted selection through them, scrolling
# when the list is taller than the screen. In the menu: arrows/Tab/Shift+Tab move, Enter accepts,
# / accepts a directory and continues into it, Ctrl+S / Ctrl+R search the menu as you type,
# Ctrl+G cancels. Styles: zshcompsys(1); menu: zshmodules(1) "The zsh/complist Module".
zmodload zsh/complist
autoload -Uz compinit
_rice_zcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$_rice_zcache" ]] || mkdir -p "$_rice_zcache"
compinit -d "$_rice_zcache/zcompdump-$ZSH_VERSION"

setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END LIST_PACKED
unsetopt MENU_COMPLETE

zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$_rice_zcache/zcompcache"
zstyle ':completion:*' menu select
zstyle ':completion:*' select-prompt "${RICE_COMPLETION_SCROLL:-%S%m of %M, %p%s}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' complete-options true
# Exact first, then case-insensitive, then partial words (f-b → foo-bar), then substring.
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:descriptions' format "${RICE_COMPLETION_HEADER:-%B%d%b}"
zstyle ':completion:*:messages' format "${RICE_COMPLETION_MESSAGE:-%d}"
zstyle ':completion:*:warnings' format "${RICE_COMPLETION_WARNING:-no matches for %d}"
# File-type colors in the menu (and for ls): coreutils defaults unless the user set LS_COLORS.
[[ -z "$LS_COLORS" ]] && (( $+commands[dircolors] )) && eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors "${RICE_COMPLETION_SELECTED:-ma=7}" ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:*:*:processes' command 'ps -u "$USER" -o pid,user,comm -w -w'
unset _rice_zcache

bindkey -M menuselect '^[[Z' reverse-menu-complete                 # Shift+Tab
bindkey -M menuselect '/' accept-and-infer-next-history            # into a directory
bindkey -M menuselect '^S' history-incremental-search-forward      # search the menu
bindkey -M menuselect '^R' history-incremental-search-backward
bindkey '^[[Z' reverse-menu-complete
