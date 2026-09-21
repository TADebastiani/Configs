import QtQuick
import qs

// Toggle switch. `checked` is input only: a click emits `toggled` with the
// requested value and never assigns `checked`, so the owner's binding
// (e.g. to adapter.enabled) stays intact.
Item {
    id: root

    property bool checked

    signal toggled(bool checked)

    implicitWidth: 36
    implicitHeight: 20
    opacity: enabled ? 1 : 0.5

    StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.active : Theme.surface2
    }

    StyledRect {
        id: thumb

        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 3 : 3
        width: 14
        height: 14
        radius: width / 2
        color: Theme.text

        Behavior on x {
            Anim {}
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: root.toggled(!root.checked)
    }
}
