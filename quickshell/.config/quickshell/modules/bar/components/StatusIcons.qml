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
    // Extra room before the first item, on top of `padding`
    readonly property int startPadding: Config.padding.extraSmall

    // Which status popup is open, if any ("", "audio", "network" or "bluetooth").
    // Held here so that only one is open at a time.
    property string openPopup

    // A popout whose data source vanished must not stay "open" in the
    // background, or it would map itself when the source comes back
    readonly property bool hasSink: Audio.sink !== null
    onHasSinkChanged: {
        if (!hasSink && openPopup === "audio")
            openPopup = "";
    }

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property bool btConnected: [...Bluetooth.devices.values].some(d => d.connected)

    // Same as hasSink: the bluetooth icon hides without an adapter, so its
    // popout must not stay "open" in the background
    readonly property bool hasAdapter: adapter !== null
    onHasAdapterChanged: {
        if (!hasAdapter && openPopup === "bluetooth")
            openPopup = "";
    }

    // Same as hasSink, and the popout also gives way to the password dialog
    readonly property bool canOpenNetwork: Network.devices.length > 0 && !Network.passwordOpen
    onCanOpenNetworkChanged: {
        if (!canOpenNetwork && openPopup === "network")
            openPopup = "";
    }

    implicitHeight: Config.sizes.bar.pillHeight
    implicitWidth: startPadding + row.implicitWidth + padding * 2

    color: Theme.surface0
    radius: Config.rounding.large

    Row {
        id: row

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: root.padding + root.startPadding
        }
        spacing: Config.spacing.small

        Repeater {
            model: Config.bar.statusIcons.filter(e => e.enabled)

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "audio"
                    delegate: Glyph {
                        id: audioIcon

                        text: Audio.volumeIcon
                        color: Audio.muted ? Theme.subtext0 : Theme.text

                        // Glyph is a plain text item: it has no hover of its own
                        HoverHandler {
                            id: audioHover

                            onHoveredChanged: {
                                if (hovered && Audio.sink !== null)
                                    root.openPopup = "audio";
                            }
                        }

                        HoverPopup {
                            target: audioIcon
                            targetHovered: audioHover.hovered
                            // Without an output there is nothing to show
                            open: root.openPopup === "audio" && Audio.sink !== null
                            onDismissRequested: {
                                if (root.openPopup === "audio")
                                    root.openPopup = "";
                            }

                            content: Component {
                                AudioPopout {}
                            }
                        }
                    }
                }

                DelegateChoice {
                    roleValue: "microphone"
                    delegate: Glyph {
                        // Shown only while the microphone is live: hidden when there
                        // is no input or when it is muted
                        visible: Audio.hasSource && !Audio.sourceMuted
                        text: Audio.micIcon
                    }
                }

                DelegateChoice {
                    roleValue: "network"
                    delegate: Glyph {
                        id: networkIcon

                        text: Network.icon
                        color: Network.connected ? Theme.text : Theme.subtext0

                        // Glyph is a plain text item: it has no hover of its own
                        HoverHandler {
                            id: networkHover

                            onHoveredChanged: {
                                if (hovered && root.canOpenNetwork)
                                    root.openPopup = "network";
                            }
                        }

                        HoverPopup {
                            target: networkIcon
                            targetHovered: networkHover.hovered
                            open: root.openPopup === "network" && root.canOpenNetwork
                            onDismissRequested: {
                                if (root.openPopup === "network")
                                    root.openPopup = "";
                            }

                            content: Component {
                                NetworkPopout {}
                            }
                        }
                    }
                }

                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Glyph {
                        id: bluetoothIcon

                        visible: root.adapter !== null
                        text: !root.btOn ? Config.icons.bluetoothOff : root.btConnected ? Config.icons.bluetoothConnected : Config.icons.bluetooth
                        color: root.btOn ? Theme.text : Theme.subtext0

                        // Glyph is a plain text item: it has no hover of its own
                        HoverHandler {
                            id: bluetoothHover

                            onHoveredChanged: {
                                if (hovered && root.adapter !== null)
                                    root.openPopup = "bluetooth";
                            }
                        }

                        HoverPopup {
                            target: bluetoothIcon
                            targetHovered: bluetoothHover.hovered
                            // Without an adapter there is nothing to show
                            open: root.openPopup === "bluetooth" && root.adapter !== null
                            onDismissRequested: {
                                if (root.openPopup === "bluetooth")
                                    root.openPopup = "";
                            }

                            content: Component {
                                BluetoothPopout {}
                            }
                        }
                    }
                }

                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: Glyph {
                        visible: Keyboard.layout !== ""
                        text: Keyboard.layout
                        width: implicitWidth
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

        // The Propo font gives every glyph its own advance (10-20 px at 20 px),
        // so each icon gets a fixed, centered cell; text items override `width`.
        width: Config.font.size.large + Config.padding.extraSmall
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent?.verticalCenter
        font.pixelSize: Config.font.size.large
    }
}
