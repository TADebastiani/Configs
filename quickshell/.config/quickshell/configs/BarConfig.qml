import QtQuick

QtObject {
    readonly property bool persistent: true
    readonly property bool showOnHover: true
    readonly property int dragThreshold: 20
    readonly property int borderWidth: 2
    readonly property int verticalPadding: 5

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
            entryId: "statusIcons"
        },
        Entry {
            entryId: "clock"
        }
    ]

    // Items of the status block, in bar order
    readonly property list<Entry> statusIcons: [
        Entry {
            entryId: "kbLayout"
        },
        Entry {
            entryId: "bluetooth"
        },
        Entry {
            entryId: "network"
        },
        Entry {
            entryId: "microphone"
        },
        Entry {
            entryId: "audio"
        }
    ]

    readonly property WorkspacesConfig workspaces: WorkspacesConfig {}
}
