# {{ name }} for zsh: syntax highlighting, autosuggestions, history search, completion menu, fzf.
# Deployed to ~/.config/zsh/theme.zsh and sourced by ~/.zshrc before the plugins, so the plugins'
# own defaults (`: ${…:=…}`) never override these. Colors are 24-bit (kitty and foot support it).

# ---- zsh-syntax-highlighting (fish-like command-line colors; Monokai roles) ----
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_HIGHLIGHT_STYLES[default]='none'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg={{ red }},bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg={{ red }}'
ZSH_HIGHLIGHT_STYLES[alias]='fg={{ green }}'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg={{ green }},underline'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg={{ cyan }}'
ZSH_HIGHLIGHT_STYLES[builtin]='fg={{ green }}'
ZSH_HIGHLIGHT_STYLES[function]='fg={{ green }}'
ZSH_HIGHLIGHT_STYLES[command]='fg={{ green }}'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg={{ green }}'
ZSH_HIGHLIGHT_STYLES[precommand]='fg={{ green }},italic'
ZSH_HIGHLIGHT_STYLES[arg0]='fg={{ green }}'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg={{ red }}'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg={{ cyan }},underline'
ZSH_HIGHLIGHT_STYLES[path]='fg={{ text }},underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg={{ overlay }},underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg={{ text }},underline'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg={{ overlay }},underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg={{ blue }}'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg={{ blue }}'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg={{ orange }}'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg={{ orange }}'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg={{ yellow }}'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg={{ yellow }}'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg={{ yellow }}'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg={{ yellow }},underline'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg={{ yellow }},underline'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg={{ yellow }},underline'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg={{ pink }},underline'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg={{ pink }}'
ZSH_HIGHLIGHT_STYLES[arithmetic-expansion]='fg={{ purple }}'
ZSH_HIGHLIGHT_STYLES[assign]='fg={{ text }}'
ZSH_HIGHLIGHT_STYLES[redirection]='fg={{ red }}'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg={{ purple }}'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg={{ purple }}'
ZSH_HIGHLIGHT_STYLES[comment]='fg={{ overlay }},italic'
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg={{ red }},bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg={{ blue }}'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg={{ purple }}'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg={{ cyan }}'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg={{ orange }}'
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='fg={{ crust }},bg={{ yellow }}'

# ---- zsh-autosuggestions: the grey "ghost" completion after the cursor ----
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg={{ overlay }}'

# ---- zsh-history-substring-search (Up/Down search history for what you typed) ----
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg={{ surface2 }},fg={{ bright }},bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg={{ red }},fg={{ crust }},bold'

# ---- Completion menu (zsh/complist), used by completion.zsh ----
# Selected entry: purple bar with dark text, the same selection as rofi and the bar.
RICE_COMPLETION_SELECTED='ma=48;2;{{ purple | sgr }};38;2;{{ crust | sgr }};1'
RICE_COMPLETION_HEADER='%F{{{ purple }}}%B%d%b%f'
RICE_COMPLETION_MESSAGE='%F{{{ overlay }}}%d%f'
RICE_COMPLETION_WARNING='%F{{{ red }}}no matches for %d%f'
RICE_COMPLETION_SCROLL='%K{{{ surface1 }}}%F{{{ text }}} %m of %M · %p · scroll with arrows, type Ctrl+S to search %f%k'

# ---- fzf (Ctrl+R history, Ctrl+T files, Alt+C directories) ----
export FZF_DEFAULT_OPTS="--color=fg:{{ text }},bg:{{ base }},hl:{{ red }},fg+:{{ bright }},bg+:{{ surface1 }},hl+:{{ red }}\
 --color=info:{{ purple }},prompt:{{ purple }},pointer:{{ pink }},marker:{{ green }},spinner:{{ pink }},header:{{ cyan }},border:{{ surface2 }}\
 --border=rounded --layout=reverse --height=40% --info=inline-right"
