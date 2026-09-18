import QtQuick
import QtQuick.Controls
import Quickshell
import qs
import qs.components
import qs.modules.bar

MouseArea {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Panels panels
    required property BarWrapper bar
    required property real borderThickness

    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    hoverEnabled: true

    Connections {
        target: root.screenState
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y

        if (y > bar.implicitHeight) {
            console.debug("[Interactions] mouse inside bar");
            bar.checkPopout(x);
        } else {
            console.debug("[Interactions] mouse outside bar");
            bar.closeTray();
        }
    }
}
