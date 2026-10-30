// Rice shell: per screen, the ASCII sky wallpaper and the Orbit Glass bar.
// Screens come and go with the KVM; Variants creates and destroys both per screen.
import QtQuick
import Quickshell
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
}
