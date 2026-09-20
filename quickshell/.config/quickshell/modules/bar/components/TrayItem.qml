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

    onEntered: {
        closeTimer.stop();
        menuRequested();
    }
    onExited: closeTimer.restart()

    // The menu lives in another window, so leaving the icon doesn't mean the
    // pointer left the menu. Only dismiss if neither is hovered after a grace period.
    Timer {
        id: closeTimer

        interval: 150
        onTriggered: {
            if (!root.containsMouse && !popupHover.hovered)
                root.menuDismissed();
        }
    }

    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath(root.modelData.icon)
    }

    PopupWindow {
        id: popup

        visible: root.menuOpen && !!root.modelData.menu
        color: "transparent"
        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight

        // Centered above the icon, resting on top of the bar window
        anchor {
            window: root.QsWindow.window
            edges: Edges.Top
            gravity: Edges.Top

            // The icon has no scene position yet when the popup is created
            onAnchoring: {
                const p = root.mapToItem(null, 0, 0);
                popup.anchor.rect = Qt.rect(p.x, 0, root.width, 1);
            }
        }

        StyledRect {
            id: background

            anchors.fill: parent
            implicitWidth: menuLoader.implicitWidth + Config.padding.large * 2
            implicitHeight: menuLoader.implicitHeight + Config.padding.large * 2
            color: Theme.surface0
            radius: Config.rounding.extraLarge

            HoverHandler {
                id: popupHover

                onHoveredChanged: {
                    if (hovered)
                        closeTimer.stop();
                    else
                        closeTimer.restart();
                }
            }

            // Recreated on each open so a submenu never survives a reopen
            Loader {
                id: menuLoader

                active: popup.visible
                anchors.centerIn: parent

                sourceComponent: TrayMenu {
                    trayItem: root.modelData.menu // qmllint disable unresolved-type
                    onCloseRequested: root.menuDismissed()
                }
            }
        }
    }
}
