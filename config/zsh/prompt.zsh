# Prompt: starship (config ~/.config/starship.toml, generated from the palette). Without starship,
# a plain prompt that still shows the exit code of a failed command.
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
else
    PROMPT='%F{blue}%~%f %(?..%F{red}[%?]%f )%(?.%F{green}.%F{red})❯%f '
fi
