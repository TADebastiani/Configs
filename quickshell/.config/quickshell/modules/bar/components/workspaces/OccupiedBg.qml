pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: root

    required property Repeater workspaces
    required property var occupied

    property list<var> pills: []

    onOccupiedChanged: {
        if (!occupied)
            return;

        let count = 0;
        const start = 0;
        const end = 0;
    }

    Repeater {
        model: {
            values: root.pills.filter(p => p)
        }
    }

    Component {
        id: pillComp

        Pill{}
    }

    component Pill: QtObject {
        property int start
        property int end
    }
}
