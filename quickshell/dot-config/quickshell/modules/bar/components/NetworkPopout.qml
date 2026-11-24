pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking as Net
import qs
import qs.configs
import qs.components
import qs.services

// Content of the network popout: Wi-Fi switch, wired status and the list of
// Wi-Fi networks. Clicking a row goes through Network.activate, which opens the
// password dialog when the network needs one.
Item {
    id: root

    readonly property bool wifiOn: Net.Networking.wifiEnabled && Net.Networking.wifiHardwareEnabled
    readonly property bool showList: wifiOn && Network.wifiDevice !== null

    readonly property int rowHeight: 32
    readonly property int maxListHeight: Config.sizes.bar.networkPopoutMaxRows * rowHeight + (Config.sizes.bar.networkPopoutMaxRows - 1) * Config.spacing.extraSmall

    // Whole bars, so that small signal changes don't reorder the list under the pointer
    function rank(network: var): int {
        return network.connected ? 2 : network.known ? 1 : 0;
    }

    function bars(network: var): int {
        return Math.floor(network.signalStrength * 5);
    }

    // Column is a positioner and rewrites its own implicit size, so the width
    // the HoverPopup measures lives on this wrapper
    implicitWidth: Config.sizes.bar.networkPopoutWidth
    implicitHeight: column.implicitHeight

    // Content is recreated on each open, so this follows the popout's lifetime
    Component.onCompleted: Network.scanRequested = true
    Component.onDestruction: {
        Network.scanRequested = false;
        Network.failedName = "";
    }

    Column {
        id: column

        width: parent.width
        spacing: Config.spacing.small

        RowLayout {
            width: parent.width
            spacing: Config.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Wi-Fi")
            }

            StyledSwitch {
                checked: Net.Networking.wifiEnabled
                enabled: Net.Networking.wifiHardwareEnabled
                onToggled: value => Net.Networking.wifiEnabled = value
            }
        }

        RowLayout {
            visible: Network.wired !== null
            width: parent.width
            spacing: Config.spacing.small

            StyledText {
                Layout.preferredWidth: 24
                Layout.minimumWidth: 24
                horizontalAlignment: Text.AlignHCenter
                text: Config.icons.ethernet
                color: Theme.active
                font.pixelSize: Config.font.size.large
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Conectado por cabo")
                color: Theme.active
                elide: Text.ElideRight
            }
        }

        StyledText {
            visible: root.showList && Network.networks.length === 0
            width: parent.width
            text: qsTr("Procurando redes...")
            color: Theme.subtext0
        }

        Flickable {
            id: flick

            visible: root.showList && Network.networks.length > 0
            width: parent.width
            height: Math.min(list.implicitHeight, root.maxListHeight)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: list

                width: flick.width
                spacing: Config.spacing.extraSmall

                Repeater {
                    // ScriptModel keeps each row's identity when the order changes
                    model: ScriptModel {
                        values: [...Network.networks].sort((a, b) => (root.rank(b) - root.rank(a)) || (root.bars(b) - root.bars(a)) || a.name.localeCompare(b.name))
                    }

                    NetworkRow {}
                }
            }
        }
    }

    component NetworkRow: Item {
        id: row

        required property var modelData

        // Null-safe: a network can vanish while its row still exists
        readonly property bool connected: modelData?.connected ?? false
        readonly property bool known: modelData?.known ?? false
        readonly property bool connecting: !!modelData && !connected && (modelData.stateChanging || Network.pending === modelData)
        readonly property bool failed: !!modelData && !connecting && Network.failedName === modelData.name
        readonly property bool available: !!modelData && Network.canConnect(modelData)

        width: parent?.width ?? 0
        implicitHeight: root.rowHeight

        RowLayout {
            anchors.fill: parent
            spacing: Config.spacing.small

            StyledText {
                Layout.preferredWidth: 24
                Layout.minimumWidth: 24
                horizontalAlignment: Text.AlignHCenter
                text: Network.signalIcon(row.modelData?.signalStrength ?? 0)
                color: row.connected ? Theme.active : row.known ? Theme.text : Theme.subtext0
                opacity: row.available ? 1 : 0.5
                font.pixelSize: Config.font.size.large
            }

            StyledText {
                Layout.fillWidth: true
                text: row.modelData?.name ?? ""
                color: row.connected ? Theme.active : row.known ? Theme.text : Theme.subtext0
                opacity: row.available ? 1 : 0.5
                elide: Text.ElideRight
            }

            StyledText {
                visible: row.connecting || row.failed
                text: row.connecting ? qsTr("Conectando...") : qsTr("Falhou")
                color: row.connecting ? Theme.subtext0 : Theme.red
            }

            StyledText {
                id: spinner

                visible: row.connecting
                text: Config.icons.loading
                color: Theme.subtext0
                font.pixelSize: Config.font.size.large

                RotationAnimator on rotation {
                    running: spinner.visible
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            StyledText {
                visible: !!row.modelData && Network.isSecured(row.modelData)
                Layout.preferredWidth: 20
                Layout.minimumWidth: 20
                horizontalAlignment: Text.AlignHCenter
                text: Config.icons.lock
                color: Theme.subtext0
                opacity: row.available ? 1 : 0.5
            }
        }

        StateLayer {
            // The popup background is surface0, the StateLayer default
            color: Theme.text
            disabled: row.connected || row.connecting || !row.available
            onClicked: Network.activate(row.modelData)
        }
    }
}
