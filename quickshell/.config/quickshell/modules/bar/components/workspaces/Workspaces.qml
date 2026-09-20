pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.configs
import qs.components
import qs.services

StyledClippingRect {
    id: root

    readonly property bool onSpecial: Hyprland.focusedMonitor?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: Hyprland.activeToplevel?.workspace.id ?? 1

    property real blur: onSpecial ? 1 : 0

    implicitHeight: Config.sizes.bar.innerHeight - Config.spacing.small
    implicitWidth: layout.implicitWidth + Config.padding.small
    radius: Config.rounding.large
    color: Theme.surface0

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: true

        layer {
            enabled: root.blur > 0
            effect: MultiEffect {
                blurEnabled: true
                blur: root.blur
                blurMax: 32
            }
        }

        RowLayout {
            id: layout

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Config.spacing.extraSmall
            spacing: 0

            Repeater {
                id: workspaces

                model: Hyprland.workspaces

                Workspace {}
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            active: Config.bar.workspaces.activeIndicator
        }

        Behavior on scale {
            Anim {
                type: Anim.FastEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.FastEffects
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
