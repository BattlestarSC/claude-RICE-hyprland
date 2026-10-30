-- Session safety: lock screen recovery.
-- If hyprlock crashes, the session stays locked behind Hyprland's red "lockdead" screen (it never
-- unlocks by itself). allow_session_lock_restore lets a new hyprlock take over the existing lock;
-- from a TTY (Ctrl+Alt+F2, log in as yourself):
--   hyprctl instances                                    # find yours (usually 0)
--   hyprctl --instance 0 eval 'hl.exec_cmd("hyprlock")'
-- That needs a login as the same user on the same machine, so it does not weaken the lock.
hl.config({
    misc = {
        allow_session_lock_restore = true,
        lockdead_screen_delay = 1000,
    },
})
