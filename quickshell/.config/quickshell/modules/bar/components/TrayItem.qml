pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
//import qs
//import qs.components.effects
//import qs.services

//import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData

    enabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: 20 //config
    implicitHeight: 20

    onClicked: event => {
        if (event.button === Qt.LeftButton) {
            console.debug("[TrayItem.onClicked] leftButton", JSON.stringify(event));
            modelData.activate();
        } else {
            console.debug("[TrayItem.onClicked] rightButton", JSON.stringify(event));
            modelData.secondaryActivate();
        }
    }

    IconImage {
        id: icon

        anchors.fill: parent
        source: Quickshell.iconPath(root.modelData.icon)
    }
    
}
