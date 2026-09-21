import QtQuick
import qs

// Horizontal slider. `value` is input only: dragging emits `moved` and never
// assigns `value`, so the owner's binding (e.g. to Audio.volume) stays intact.
Item {
    id: root

    property real value
    property real maxValue: 1

    // Handle position along the track, 0..1. Clamped so a value above maxValue
    // (e.g. a 120 % volume) draws a full slider.
    readonly property real ratio: maxValue > 0 ? Math.max(0, Math.min(value / maxValue, 1)) : 0

    signal moved(real value)

    // The handle center travels from handle.width / 2 to width - handle.width / 2
    function valueAt(x: real): real {
        const span = width - handle.width;
        if (span <= 0)
            return 0;
        return Math.max(0, Math.min((x - handle.width / 2) / span, 1)) * maxValue;
    }

    implicitWidth: 200
    implicitHeight: 24

    StyledRect {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: height / 2
        color: Theme.surface2

        StyledRect {
            width: handle.x + handle.width / 2
            height: parent.height
            radius: parent.radius
            color: Theme.active
        }
    }

    StyledRect {
        id: handle

        anchors.verticalCenter: parent.verticalCenter
        x: root.ratio * (root.width - width)
        width: 14
        height: 14
        radius: width / 2
        color: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPressed: event => root.moved(root.valueAt(event.x))
        onPositionChanged: event => {
            if (pressed)
                root.moved(root.valueAt(event.x));
        }
    }
}
