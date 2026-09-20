pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.configs
import qs.components
import qs.components.containers
import qs.modules.bar
import qs.services

StyledWindow {
    id: root

    name: "drawers"

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: Config.sizes.bar.innerHeight + Config.bar.verticalPadding * 2

    StyledRect {
        anchors.fill: parent
        color: Theme.base
        opacity: 0.8

        // Rectangle borders are all-sides, so the top edge is its own item
        StyledRect {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: Config.bar.borderWidth
            color: Theme.surface0
            opacity: 1
        }
    }

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
