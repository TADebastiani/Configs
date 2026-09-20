pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services

Text {
    id: root

    property bool animate: false

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Theme.text
    font.family: Theme.fontFamily

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }
}
