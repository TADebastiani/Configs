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

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.padding.extraSmall
    readonly property int spacing: Config.spacing.extraSmall

    property bool expanded: true

    readonly property real nonAnimWidth: {
        if (!BarConfig.tray?.compact)
            return layout.implicitWidth + padding * 2;
        if (expanded)
            return expandIcon.implicitWidth + layout.implicitWidth + spacing + padding;
        return expandIcon.implicitWidth + padding;
    }

    visible: width > 0
    implicitHeight: Config.sizes.bar.innerHeight
    implicitWidth: nonAnimWidth

    color: Theme.surface1
    radius: Config.rounding.large

    Row {
        id: layout

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: root.padding
        }
        spacing: Config.spacing.small

        opacity: root.expanded ? 1 : 0

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Config.anim.standardDecel
            }
        }
        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Config.anim.standardDecel
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

            TrayItem {}
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

        //active: BarConfig.tray?.compact && items > 0
        active: false

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
