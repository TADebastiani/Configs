pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs
import qs.configs
import qs.components

MouseArea {
    id: root

    required property SystemTrayItem modelData
    property bool menuOpen

    signal menuRequested
    signal menuDismissed

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: 20 //config
    implicitHeight: 20

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    onEntered: menuRequested()

    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath(root.modelData.icon)
    }

    HoverPopup {
        target: root
        targetHovered: root.containsMouse
        open: root.menuOpen && !!root.modelData.menu
        onDismissRequested: root.menuDismissed()

        content: Component {
            TrayMenu {
                trayItem: root.modelData.menu // qmllint disable unresolved-type
                onCloseRequested: root.menuDismissed()
            }
        }
    }
}
