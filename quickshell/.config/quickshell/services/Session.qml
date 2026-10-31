pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Session menu state and actions. `qs ipc call session toggle` opens the menu.
Singleton {
    id: root

    property bool open

    // Answered by logind; false until the first reply
    property bool canHibernate

    function refresh(): void {
        canHibernateCheck.running = true;
    }

    // Closes the menu first: hyprlock can't take over while the menu holds the keyboard
    function run(action: string): void {
        open = false;

        switch (action) {
        case "poweroff":
        case "reboot":
        case "suspend":
            Quickshell.execDetached(["systemctl", action]);
            break;
        case "hibernate":
            if (canHibernate)
                Quickshell.execDetached(["systemctl", action]);
            break;
        case "lock":
            Quickshell.execDetached(["hyprlock"]);
            break;
        case "logout":
            Hyprland.dispatch("hl.dsp.exit()");
            break;
        }
    }

    Process {
        id: canHibernateCheck

        running: true
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "CanHibernate"]

        stdout: StdioCollector {
            onStreamFinished: root.canHibernate = text.includes('"yes"')
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            root.open = !root.open;
        }
    }
}
