pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property list<ShellScreen> screens: Quickshell.screens

    function isExcluded(screen: ShellScreen): bool {
        return false; // mock value for now
    }
}
