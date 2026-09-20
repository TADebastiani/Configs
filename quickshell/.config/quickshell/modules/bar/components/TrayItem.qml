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

        readonly property bool wantOpen: root.menuOpen && !!root.modelData.menu

        // The content is built while the window is still unmapped, and the window
        // is only mapped once its size stopped changing. Otherwise it would show
        // up small and then reshape itself while the slide-in already runs.
        // Stays mapped while the slide-out runs.
        property bool ready

        visible: (wantOpen && ready) || slideOut.running
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

        // The window ends where the bar starts, so clipping here makes the menu
        // look like it rises out from behind the bar
        Item {
            id: slide

            // 1 = fully below the window edge (hidden), 0 = final position
            property real hidden: 1
            property int duration: 400

            anchors.fill: parent
            clip: true

            Anim {
                id: slideIn

                target: slide
                property: "hidden"
                to: 0
                type: Anim.Emphasized
                duration: slide.duration
                // Anim.Emphasized's own curve reaches 1 at 25% of the time
                easing.bezierCurve: Config.anim.emphasizedDecel
            }

            Anim {
                id: slideOut

                target: slide
                property: "hidden"
                to: 1
                type: Anim.Emphasized
                duration: slide.duration
                easing.bezierCurve: Config.anim.emphasizedAccel
            }

            StyledRect {
                id: background

                width: parent.width
                height: parent.height
                y: slide.hidden * height
                implicitWidth: menuLoader.implicitWidth + Config.padding.medium * 2
                implicitHeight: menuLoader.implicitHeight + Config.padding.large * 2
                color: Theme.surface0
                radius: Config.rounding.small

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

                    active: popup.wantOpen || popup.visible
                    anchors.centerIn: parent

                    sourceComponent: TrayMenu {
                        trayItem: root.modelData.menu // qmllint disable unresolved-type
                        onCloseRequested: root.menuDismissed()
                    }
                }
            }
        }

        Timer {
            id: settle

            interval: 50
            onTriggered: {
                popup.ready = true;
                slideIn.restart();
            }
        }

        Connections {
            target: background

            function onImplicitWidthChanged(): void {
                if (popup.wantOpen && !popup.ready)
                    settle.restart();
            }

            function onImplicitHeightChanged(): void {
                if (popup.wantOpen && !popup.ready)
                    settle.restart();
            }
        }

        // Both animations start from wherever the menu currently is, so a
        // hover during the slide-out reverses it instead of jumping
        onWantOpenChanged: {
            if (wantOpen) {
                slideOut.stop();
                if (visible)
                    slideIn.restart();
                else
                    settle.restart();
            } else {
                settle.stop();
                if (visible) {
                    slideIn.stop();
                    slideOut.restart();
                }
            }
        }

        onVisibleChanged: {
            if (!visible) {
                slideIn.stop();
                slideOut.stop();
                slide.hidden = 1;
                ready = false;
            }
        }
    }
}
