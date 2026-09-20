pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs
import qs.configs
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property int padding: Config.padding.extraSmall
    readonly property int spacing: Config.spacing.extraSmall

    // Tray item whose menu is currently open, if any
    property SystemTrayItem menuItem

    readonly property bool expanded: hover.hovered || menuItem !== null
    readonly property bool compact: !!Config.bar.tray?.compact

    readonly property real nonAnimWidth: {
        if (!compact)
            return layout.implicitWidth + padding * 2;
        if (expanded)
            return expandIcon.implicitWidth + layout.implicitWidth + spacing + padding;
        return expandIcon.implicitWidth + padding;
    }

    visible: width > 0
    implicitHeight: Config.sizes.bar.innerHeight - Config.spacing.small
    implicitWidth: nonAnimWidth

    color: Theme.surface0
    radius: Config.rounding.large

    HoverHandler {
        id: hover
    }

    Row {
        id: layout

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: root.padding
        }
        spacing: Config.spacing.small

        opacity: root.expanded ? 0.5 : 1

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing.bezierCurve: Config.anim.standardDecel
            }
        }
        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Config.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values
            }

            TrayItem {
                // Collapsed compact tray only shows the expand icon
                enabled: !root.compact || root.expanded
                menuOpen: root.menuItem === modelData
                onMenuRequested: root.menuItem = modelData
                onMenuDismissed: {
                    if (root.menuItem === modelData)
                        root.menuItem = null;
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: expandIcon
        asynchronous: true
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
        }

        active: root.compact && items.count > 0

        sourceComponent: Item {
            implicitHeight: expandIconInner.implicitHeight
            implicitWidth: expandIconInner.implicitWidth - Config.padding.small

            IconImage {
                id: expandIconInner
                implicitSize: 15

                anchors{
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: -Config.padding.small
                }
                source: Quickshell.iconPath("folder")

                Behavior on rotation {
                    Anim {}
                }
                Behavior on anchors.rightMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }
}
