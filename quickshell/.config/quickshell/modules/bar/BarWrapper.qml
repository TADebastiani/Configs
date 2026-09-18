pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.components
import "popouts" as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    readonly property bool disabled: false // add config
    readonly property int clampedHeight: Math.max(Config.border.minThickness, implicitHeight)
    readonly property int padding: Math.max(Config.padding.small, Config.border.thickness)
    readonly property int contentHeight: Config.sizes.bar.innerHeight + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentHeight : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    
    property bool isHovered

    clip: false
    visible: height > Config.border.thickness
    implicitHeight: fullscreen ? 0 : Config.border.thickness
    implicitWidth: screen.width


    transitions: [
        Transition {
            from: ""
            to: "visible"
            
            Anim {
                target: root
                property: "implicitHeight"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                type: Anim.Emphasized
            }
        }
    ]

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitHeight: root.contentHeight
        }
    }

    Loader {
        id: content
        
        active: root.shouldBeVisible
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        sourceComponent: Bar {
            height: root.contentHeight
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts
        }
    }

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(x: real): void {
        (content.item as Bar)?.checkPopout(x);
    }

}
