pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs
import qs.configs
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property real borderThickness: Config.border.thickness
    readonly property real borderLayoutThickness: Config.border.thickness

    property color surfaceColor: Theme.surface0

    name: "drawers"
    mask: regions

    anchors {
        bottom: true
        left: true
        right: true
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: {
            if (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1) {
                return true;
            }
            return false;
        }
        windows: [root]
        onCleared: {
            root.screenState.launcher = false;
            root.screenState.session = false;
            root.screenState.sidebar = false;
            root.screenState.dashboard = false;
            panels.popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: root.screenState.session || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Theme.crust

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceColor.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Theme.crust, Math.max(0, root.shadowOpacity))
        }

        PanelBg {
            id: popoutBg
            property real extraHeight: panels.popouts.isDetached ? 0 : 0.2

            panel: panels.popoutsWrapper
            //deformAmount
            y: panels.popoutsWrapper.y + panels.popouts.y + bar.implicitHeight - panels.popouts.height * extraHeight
            implicitHeight: panels.popouts.height * (1 + extraHeight)

            Behavior on extraHeight {
                Anim {}
            }
        }
    }

    Interactions {
        id: interactions
        screen: root.screen
        screenState: root.screenState
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness

        Panels {
            id: panels

            screen: root.screen
            screenState: root.screenState
            bar: bar
            borderThickness: root.borderThickness

            // popouts.transform: Matrix4x4 {
            //     matrix: popoutBg
            // }
        }

        BarWrapper {
            id: bar

            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts
            fullscreen: false // content.hasFullscreen

        }
    }

    Behavior on surfaceColor {
        CAnim {}
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "rootWindow"
        component: root
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "interactionWrapper"
        component: interactions
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panels
    }

    component PanelBg: Rectangle {
        required property Item panel
        property real deformAmount: 0.15

        //group
        x: panel.x + root.borderThickness
        y: panel.y + bar.implicitHeight
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Config.rounding.extraLarge
        //deformScale: (deformAmount * 2) / 10000 // Config
    }
}
