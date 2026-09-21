pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.configs
import qs.components
import qs.services

// Status icons block: audio, microphone, network, bluetooth, keyboard layout.
// Order and visibility come from Config.bar.statusIcons.
StyledRect {
    id: root

    readonly property int padding: Config.padding.extraSmall

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property bool btConnected: [...Bluetooth.devices.values].some(d => d.connected)

    implicitHeight: Config.sizes.bar.innerHeight - Config.spacing.small
    implicitWidth: row.implicitWidth + padding * 2

    color: Theme.surface1
    radius: Config.rounding.large

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Config.spacing.small

        Repeater {
            model: Config.bar.statusIcons.filter(e => e.enabled)

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "audio"
                    delegate: Glyph {
                        text: Audio.volumeIcon
                        color: Audio.muted ? Theme.subtext0 : Theme.text
                    }
                }

                DelegateChoice {
                    roleValue: "microphone"
                    delegate: Glyph {
                        visible: Audio.hasSource
                        text: Audio.micIcon
                        color: Audio.sourceMuted ? Theme.subtext0 : Theme.text
                    }
                }

                DelegateChoice {
                    roleValue: "network"
                    delegate: Glyph {
                        text: Network.icon
                        color: Network.connected ? Theme.text : Theme.subtext0
                    }
                }

                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Glyph {
                        visible: root.adapter !== null
                        text: !root.btOn ? Config.icons.bluetoothOff : root.btConnected ? Config.icons.bluetoothConnected : Config.icons.bluetooth
                        color: root.btOn ? Theme.text : Theme.subtext0
                    }
                }

                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: Glyph {
                        visible: Keyboard.layout !== ""
                        text: Keyboard.layout
                        font.family: Config.font.pixel
                        font.pixelSize: Config.font.pixelSize
                    }
                }
            }
        }
    }

    component Glyph: StyledText {
        required property var modelData
        required property int index

        anchors.verticalCenter: parent?.verticalCenter
        font.pixelSize: Config.font.size.large
    }
}
