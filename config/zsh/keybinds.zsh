# Emacs-style line editing (as in bash and fish) plus the usual PC keys.
bindkey -e
bindkey '^[[H' beginning-of-line       # Home
bindkey '^[[F' end-of-line             # End
bindkey '^[[3~' delete-char            # Delete
bindkey '^[[1;5D' backward-word        # Ctrl+Left
bindkey '^[[1;5C' forward-word         # Ctrl+Right
bindkey '^H' backward-kill-word        # Ctrl+Backspace (kitty, foot)
bindkey '^[[3;5~' kill-word            # Ctrl+Delete
# Edit the command line in $EDITOR with Ctrl+X Ctrl+E.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
