# Adds pam_gnome_keyring to a PAM service file. Run with the file twice: awk -f this FILE FILE.
# Pass 1 finds the last auth and session lines (a leading "-" marks an optional module); pass 2
# prints the file with the module after each. A file without such a line gets it at the end.
# -v module=PATH names the module (default pam_gnome_keyring.so; FreeBSD's OpenPAM is given
# the full path of the port's module).
BEGIN { if (module == "") module = "pam_gnome_keyring.so" }
NR == FNR { t = $1; sub(/^-/, "", t); if (t == "auth") last_auth = FNR; if (t == "session") last_session = FNR; next }
{ print }
FNR == last_auth    { print "auth       optional     " module }
FNR == last_session { print "session    optional     " module " auto_start" }
END {
    if (!last_auth)    print "auth       optional     " module
    if (!last_session) print "session    optional     " module " auto_start"
}
