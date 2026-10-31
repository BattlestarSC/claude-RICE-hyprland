# Console autostart, where there is no graphical login screen (FreeBSD has no greetd): logging in
# on the console named in ~/.config/rice/tty-autostart starts Hyprland. The installer writes
# that file; delete it to keep the plain console. Docs: platforms.md#sessions-without-systemd.
if [[ -o login && -z ${WAYLAND_DISPLAY:-} && -r ${XDG_CONFIG_HOME:-$HOME/.config}/rice/tty-autostart ]] &&
    [[ ${TTY:-} == "$(<${XDG_CONFIG_HOME:-$HOME/.config}/rice/tty-autostart)" ]] &&
    (( $+commands[rice-session] )); then
    exec rice-session hyprland
fi
