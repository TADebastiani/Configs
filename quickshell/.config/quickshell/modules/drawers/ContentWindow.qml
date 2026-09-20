pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.configs
import qs.components.containers
import qs.modules.bar
import qs.services

StyledWindow {
    id: root

    readonly property int barPadding: Math.max(Config.padding.small, Config.border.thickness)

    name: "drawers"

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: Config.sizes.bar.innerHeight + barPadding * 2

    Bar {
        id: bar

        screen: root.screen
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }
}
