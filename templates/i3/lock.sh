# {{ name }} palette for i3lock-color, sourced by rice-session (lock on X11). i3lock-color takes
# RRGGBBAA without '#'. The ring follows hyprlock.conf: dark glass inside, purple ring, green
# while verifying, red on a wrong password; the ASCII sky still is the background.
RICE_I3LOCK_COLORS=(
    --inside-color={{ mantle | bare }}D9 --ring-color={{ purple | bare }}FF
    --insidever-color={{ mantle | bare }}D9 --ringver-color={{ green | bare }}FF
    --insidewrong-color={{ mantle | bare }}D9 --ringwrong-color={{ red | bare }}FF
    --line-color={{ crust | bare }}00 --separator-color={{ crust | bare }}00
    --keyhl-color={{ cyan | bare }}FF --bshl-color={{ orange | bare }}FF
    --verif-color={{ green | bare }}FF --wrong-color={{ red | bare }}FF --modif-color={{ subtext | bare }}FF
    --time-color={{ bright | bare }}FF --date-color={{ subtext | bare }}FF
    --layout-color={{ subtext | bare }}FF --greeter-color={{ text | bare }}FF
)
