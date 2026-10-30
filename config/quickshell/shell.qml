//@ pragma DataDir $BASE/rice/quickshell
// DataDir: Quickshell.dataPath() resolves to ~/.local/share/rice/quickshell (not a path hash), so
// install.sh can put the sky glyph atlases there (bin/rice-sky-atlas).
// Rice shell: per screen, the ASCII sky wallpaper, the Orbit Glass bar and the screensaver
// overlay (hidden until hypridle starts it); notification popups on
// the primary (leftmost) screen. Screens come and go with the KVM; Variants creates and destroys
// the per-screen windows, and the popups follow Screens.primary.
import QtQuick
import Quickshell
import qs.services
import "sky"
import "bar"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        SaverWindow {}
    }
    NotificationPopups {
        screen: Screens.primary
    }
}
