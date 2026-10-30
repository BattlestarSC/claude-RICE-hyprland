# Loaded last (after local.zsh). zsh-syntax-highlighting must be the last plugin that wraps zle
# widgets; zsh-history-substring-search must come after it (both projects' instructions).
_rice_source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Up/Down search history for what is already typed (fish behavior).
if _rice_source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh; then
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OA' history-substring-search-up       # application cursor mode
    bindkey '^[OB' history-substring-search-down
fi
unfunction _rice_source 2>/dev/null
