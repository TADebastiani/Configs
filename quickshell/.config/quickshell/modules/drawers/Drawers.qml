pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.components
import qs.components.containers
import qs.modules.bar
import qs.services

Variants {
    id: root

    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        ContentWindow {
            id: content
            screen: scope.modelData
        }

    }
}
