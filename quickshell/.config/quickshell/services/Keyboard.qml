pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // Short code of the active layout ("US"); empty until the first read
    property string layout: ""

    // "English (US, intl., with dead keys)" -> "US": the first item inside the
    // parentheses. Enough for a single layout; revisit if another name format shows up.
    function shortName(name: string): string {
        const m = /\(([^,)]+)/.exec(name);
        return m ? m[1].trim() : "";
    }

    function apply(name: string): void {
        const code = shortName(name);
        if (code !== "")
            layout = code;
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards.find(k => k.main);
                    if (kb)
                        root.apply(kb.active_keymap);
                } catch (e) {
                    // keep the previous value
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name !== "activelayout")
                return;
            const comma = event.data.indexOf(",");
            if (comma >= 0)
                root.apply(event.data.slice(comma + 1));
        }
    }
}
