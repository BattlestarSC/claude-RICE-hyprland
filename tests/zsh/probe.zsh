# Assertions run inside the interactive test shell (tests/zsh/run.sh).
check() { if eval "$2"; then print -r -- "ok   $1"; else print -r -- "FAIL $1"; fi }
check 'options'              '[[ -o autocd && -o sharehistory && -o histignorealldups && ! -o flowcontrol && -o completeinword ]]'
check 'menu select'          '[[ "$(zstyle -L ":completion:*" menu)" == *"menu select"* ]]'
check 'selection color'      '[[ "$(zstyle -L ":completion:*:default" list-colors)" == *"ma=48;2;"* ]]'
check 'file colors'          '[[ -n "$LS_COLORS" ]]'
check 'menu: Ctrl+S search'  '[[ "$(bindkey -M menuselect "^S")" == *history-incremental-search-forward* ]]'
check 'menu: / descends'     '[[ "$(bindkey -M menuselect "/")" == *accept-and-infer-next-history* ]]'
check 'theme loaded'         '[[ "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" == fg=#* ]]'
check 'history file'         '[[ -d "${HISTFILE:h}" ]]'
check 'man page colors'      '[[ $GROFF_NO_SGR == 1 && $LESS_TERMCAP_md == *"38;2;"* && $LESS_TERMCAP_us == *"38;2;"* ]]'
check 'helper removed'       '(( ! $+functions[_rice_source] ))'
if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    check 'syntax highlighting' '(( $+functions[_zsh_highlight] )) && [[ "$ZSH_HIGHLIGHT_STYLES[command]" == fg=#* ]]'
fi
if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    check 'autosuggestions' '(( $+functions[_zsh_autosuggest_start] ))'
fi
if [[ -r /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    check 'Up = substring search' '[[ "$(bindkey "^[[A")" == *history-substring-search-up* ]]'
fi
if (( $+commands[nvim] )); then
    check 'EDITOR = nvim'        '[[ "$EDITOR" == nvim && "$VISUAL" == nvim ]]'
fi
