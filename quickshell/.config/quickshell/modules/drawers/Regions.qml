pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: Config.border.thickness
    readonly property real clampedThickness: Config.border.clampedThickness()

    x: bar.clampedHeight + win.dragMaskPadding
    y: clampedThickness + win.dragMaskPadding
    height: win.height - bar.clampedHeight - clampedThickness - win.dragMaskPadding * 2
    width: win.width - clampedThickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    // Dashboard
    // Launcher
    // Session
    // Sidebar
    // OSD
    // Notifications
    // Utilities
    // PopoutsWrapper

    component R: Region {
        required property Item panel

        x: panel.x + root.borderThickness
        y: panel.y + root.bar.implicitHeight
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
