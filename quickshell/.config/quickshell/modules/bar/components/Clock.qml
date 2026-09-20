pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color textColor: Theme.text
    readonly property int padding: Config.padding.medium

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: Config.sizes.bar.innerHeight

    color: "transparent" // Theme.surface0
    radius: Config.rounding.small

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 0

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.timeStr
            font {
                family: Config.font.mono
                pixelSize: Config.font.size.medium
                bold: true
            }
            color: root.textColor
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.dateStr
            color: root.textColor
            font.bold:true
        }
    }
}
