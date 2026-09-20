import QtQuick
import Quickshell.Hyprland
import qs

Repeater {
    model: Hyprland.workspaces

    delegate: Rectangle {
        id: wsPill
        required property HyprlandWorkspace modelData

        implicitWidth: Math.max(24, wsLabel.implicitWidth + 16)
        implicitHeight: 22
        radius: Theme.pillRadius
        color: modelData.focused ? Theme.mauve : modelData.urgent ? Theme.red : modelData.active ? Theme.surface1 : "transparent"

        Text {
            id: wsLabel
            anchors.centerIn: parent
            text: wsPill.modelData.name
            font.pixelSize: Theme.fontSize - 1
            font.bold: wsPill.modelData.focused
            color: wsPill.modelData.focused ? Theme.crust : Theme.subtext1
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wsPill.modelData.activate()
        }
    }
}
