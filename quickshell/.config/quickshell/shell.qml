//@ pragma IconTheme Papirus
import QtQuick
import Quickshell
import qs
import qs.modules.bar
import qs.modules.drawers
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

    // Variants {
    //     model: Quickshell.screens
    //     OldBar {}
    // }

}
