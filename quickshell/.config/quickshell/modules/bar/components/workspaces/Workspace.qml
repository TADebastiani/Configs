pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import qs
import qs.configs
import qs.components

RowLayout {
    id: root

    required property int index
    required property HyprlandWorkspace modelData

    readonly property bool isWorkspace: true

    readonly property int ws: modelData.id
    readonly property bool focused: modelData.focused
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]
    readonly property int focusedShape: focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)]

    Layout.alignment: Qt.AlignLeft
    //Layout.preferredWidth: size

    spacing: 0

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Loader {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignLeft
        Layout.preferredHeight: Config.sizes.bar.innerHeight - Config.padding.small
        sourceComponent: shapeComponent

        onItemChanged: root.updateShape()
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: Config.sizes.bar.innerHeight - Config.padding.small

            color: root.focused ? Theme.mauve : Theme.overlay0
            scale: root.focused ? 2 / 3 : 2 / 4

            animationEasing: Config.anim.expressiveFastEffects
            animationDuration: Config.anim.durations.expressiveFastEffects 

            StyledText {
                text: root.ws
                color: root.focused ? Theme.surface1 : Theme.surface1
                verticalAlignment: Qt.AlignVCenter
                horizontalAlignment: Qt.AlignHCenter
                scale: 3 / 4
                font.pixelSize: 30
                font.bold: true

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
            }

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {
                    type: Anim.FastEffects
                }
            }
        }
    }

    Component {
        id: textComponent

        StyledText {
            animate: true
            text: {
                if (root.focused) {
                    const label = BarConfig.workspaces.activeLabel;
                    if (label)
                        return label;
                }

                const label = BarConfig.workspaces.label;
                if (label)
                    return label;

                const ws = Hyprland.workspaces.values.find(w => w.id === root.ws);
                const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];

                //const upper = BarConfig.workspaces.capitalisation;
                return wsName;
            }
            color: Theme.text
            verticalAlignment: Qt.AlignVCenter
        }
    }

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;
        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)]
            //shape.shape = focusedShape;
        else
            shape.shape = MaterialShape.Circle;
    }

    Behavior on Layout.preferredWidth {
        Anim {}
    }
}
