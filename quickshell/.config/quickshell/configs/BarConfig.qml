pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property list<Entry> entries: [
        Entry {
            entryId: "workspaces"
        },
        Entry {
            entryId: "activeWindow"
        },
        Entry {
            entryId: "spacer"
        },
        Entry {
            entryId: "tray"
        },
        Entry {
            entryId: "clock"
        }
    ]

    readonly property alias workspaces: workspaces

    QtObject {
        id: workspaces

        readonly property int shown: 5
        readonly property bool activeIndicator: true
        readonly property bool occupiedBg: false
        readonly property bool showWindows: true
        readonly property bool showWindowsOnSpecialWorkspaces: true
        readonly property int maxWindowIcons: 5
        readonly property bool activeTrail: false
    }
}
