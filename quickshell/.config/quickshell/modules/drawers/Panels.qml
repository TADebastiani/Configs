import QtQuick
import Quickshell
import qs.components
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Bar.BarWrapper bar
    required property real borderThickness

    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper

    anchors {
        fill: parent
        margins: borderThickness
        bottomMargin: bar.implicitHeight
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapper
        screen: root.screen
        borderThickness: root.borderThickness

    }
    
}
