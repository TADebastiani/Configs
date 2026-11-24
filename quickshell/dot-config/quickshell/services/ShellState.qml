pragma Singleton

import QtQuick
import Quickshell
import qs.components
import qs.services

Singleton {
    property ShellRoot shellRoot

    Variants {
        id: states
        model: Screens.screens

        ScreenState {}
    }

    Variants {
        id: components
        model: Screens.screens
        Components {}
    }

    function forScreen(screen: ShellScreen): ScreenState {
        for (const s of states.instances) {
            if (s.modelData === screen)
                return s;
        }
        return null;
    }

    function componentsFor(screen: ShellScreen): Components {
        for (const c of components.instances) {
            if (c.modelData === screen)
                return c;
        }
        return null;
    }

    component Components: QtObject {
        required property ShellScreen modelData

        property var bar
    }

    component ComponentRef: QtObject {
        required property ShellScreen screen
        required property string slot
        required property var component

        readonly property QtObject target: ShellState.componentsFor(screen)

        onTargetChanged: {
            if (target)
                target[slot] = component;
        }
        Component.onDestruction: {
            if (target && target[slot] === component)
                target[slot] = null;
        }
    }
}
