pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.configs
import qs.components
// Must come after qs.components: `Audio` has to resolve to the singleton in
// services, not to components/Audio.qml
import qs.services

// Content of the audio popout: output row, then input row. Each row hides
// itself when its device is missing.
Item {
    id: root

    // Column is a positioner and rewrites its own implicit size, so the width
    // the HoverPopup measures lives on this wrapper
    implicitWidth: Config.sizes.bar.audioPopoutWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column

        width: parent.width
        spacing: Config.spacing.medium

        AudioRow {
            visible: Audio.sink !== null
            icon: Audio.volumeIcon
            muted: Audio.muted
            volume: Audio.volume
            deviceName: Audio.sinkName
            onMuteToggled: Audio.setMuted(!Audio.muted)
            onVolumeMoved: v => Audio.setVolume(v)
        }

        AudioRow {
            visible: Audio.hasSource
            icon: Audio.micIcon
            muted: Audio.sourceMuted
            volume: Audio.sourceVolume
            deviceName: Audio.sourceName
            onMuteToggled: Audio.setSourceMuted(!Audio.sourceMuted)
            onVolumeMoved: v => Audio.setSourceVolume(v)
        }
    }

    component AudioRow: Column {
        id: row

        required property string icon
        required property bool muted
        required property real volume
        required property string deviceName

        signal muteToggled
        signal volumeMoved(real value)

        width: parent.width
        spacing: Config.spacing.extraSmall

        RowLayout {
            width: parent.width
            spacing: Config.spacing.small

            StyledRect {
                Layout.preferredWidth: 32
                Layout.minimumWidth: 32
                Layout.preferredHeight: 32
                radius: Config.rounding.small

                StyledText {
                    anchors.centerIn: parent
                    text: row.icon
                    color: row.muted ? Theme.subtext0 : Theme.text
                    font.pixelSize: Config.font.size.large
                }

                StateLayer {
                    // The popup background is surface0, the StateLayer default
                    color: Theme.text
                    onClicked: row.muteToggled()
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: row.volume
                onMoved: v => row.volumeMoved(v)
            }

            StyledText {
                Layout.preferredWidth: 40
                Layout.minimumWidth: 40
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: Math.round(row.volume * 100) + "%"
            }
        }

        StyledText {
            width: parent.width
            text: row.deviceName
            color: Theme.subtext0
            elide: Text.ElideRight
        }
    }
}
