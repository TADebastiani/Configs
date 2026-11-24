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
        source: root.modelData.icon // already an image:// URL, don't wrap in iconPath()
        opacity: root.containsMouse || root.menuOpen ? 0.5 : 1

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
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
