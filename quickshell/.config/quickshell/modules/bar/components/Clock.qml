pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.configs
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color textColor: Theme.text
    readonly property int padding: Config.padding.medium
    //readonly property var font

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: Config.sizes.bar.innerHeight

    color: Theme.surface1
    radius: Config.rounding.large

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Config.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.timeStr
            //font
            color: root.textColor
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.dateStr
            //font
            color: root.textColor
        }
    }
}
