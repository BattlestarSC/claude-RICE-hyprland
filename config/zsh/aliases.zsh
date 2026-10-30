# Aliases. eza (if installed) replaces ls, with icons from the Nerd Font.
if (( $+commands[eza] )); then
    alias ls='eza --icons=auto --group-directories-first'
    alias ll='eza -l --git --icons=auto --group-directories-first'
    alias la='eza -la --git --icons=auto --group-directories-first'
    alias lt='eza --tree --level=2 --icons=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -l --color=auto'
    alias la='ls -la --color=auto'
fi
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
# Arch installs Helix as `helix` (`hx` belongs to the hex package); keep the upstream name too.
if (( ! $+commands[hx] && $+commands[helix] )); then
    alias hx='helix'
fi
