//@ pragma IconTheme Papirus
import QtQuick
import Quickshell
import qs
import qs.modules.bar
import qs.modules.drawers
import qs.modules.network
import qs.modules.osd
import qs.modules.session
import qs.components
import qs.components.containers
import qs.services

// Entry point. Instantiates one Bar per connected screen.
ShellRoot {
    id: root

    settings.watchFiles: true

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    Drawers {}

    SessionMenu {}

    Osd {}

    PasswordDialog {}

    // Variants {
    //     model: Quickshell.screens
    //     OldBar {}
    // }

}
