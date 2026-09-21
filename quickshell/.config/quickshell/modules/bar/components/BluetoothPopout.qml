pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.configs
import qs.components

// Content of the bluetooth popout: adapter switches, a device count and the
// list of every known device. It reads and writes Quickshell.Bluetooth
// directly; there is no service in between.
Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    // The rest of the popout is only shown once the adapter is fully on
    readonly property bool showDetails: adapter?.state === BluetoothAdapterState.Enabled
    // Not while the adapter is switching on/off or blocked
    readonly property bool switchable: adapter?.state === BluetoothAdapterState.Enabled || adapter?.state === BluetoothAdapterState.Disabled

    readonly property int deviceCount: Bluetooth.devices.values.length
    readonly property int connectedCount: [...Bluetooth.devices.values].filter(d => d.connected).length

    readonly property int rowHeight: 32
    readonly property int maxListHeight: Config.sizes.bar.bluetoothPopoutMaxRows * rowHeight + (Config.sizes.bar.bluetoothPopoutMaxRows - 1) * Config.spacing.extraSmall

    // BlueZ theme icon name -> glyph; anything unknown gets the generic one
    function deviceGlyph(icon: string): string {
        switch (icon) {
        case "audio-headset":
            return Config.icons.btHeadset;
        case "audio-headphones":
            return Config.icons.btHeadphones;
        case "audio-card":
            return Config.icons.btSpeaker;
        case "input-gaming":
            return Config.icons.btGamepad;
        case "input-keyboard":
            return Config.icons.btKeyboard;
        case "input-mouse":
            return Config.icons.btMouse;
        case "input-tablet":
            return Config.icons.btTablet;
        case "phone":
            return Config.icons.btPhone;
        case "computer":
            return Config.icons.btComputer;
        case "printer":
            return Config.icons.btPrinter;
        case "camera-photo":
        case "camera-video":
            return Config.icons.btCamera;
        default:
            return Config.icons.bluetooth;
        }
    }

    // Column is a positioner and rewrites its own implicit size, so the width
    // the HoverPopup measures lives on this wrapper
    implicitWidth: Config.sizes.bar.bluetoothPopoutWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column

        width: parent.width
        spacing: Config.spacing.small

        SwitchRow {
            label: qsTr("Ativado")
            checked: root.adapter?.enabled ?? false
            switchEnabled: root.switchable
            onToggled: value => {
                if (root.adapter)
                    root.adapter.enabled = value;
            }
        }

        SwitchRow {
            visible: root.showDetails
            label: qsTr("Buscando")
            checked: root.adapter?.discovering ?? false
            onToggled: value => {
                if (root.adapter)
                    root.adapter.discovering = value;
            }
        }

        StyledText {
            visible: root.showDetails
            width: parent.width
            color: Theme.subtext0
            text: {
                const total = root.deviceCount;
                const connected = root.connectedCount;
                let s = total === 1 ? qsTr("%1 dispositivo").arg(total) : qsTr("%1 dispositivos").arg(total);
                if (connected > 0)
                    s += connected === 1 ? qsTr(" (%1 conectado)").arg(connected) : qsTr(" (%1 conectados)").arg(connected);
                return s;
            }
        }

        Flickable {
            id: flick

            visible: root.showDetails
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
                        values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
                    }

                    DeviceRow {}
                }
            }
        }
    }

    component SwitchRow: RowLayout {
        id: switchRow

        required property string label
        property alias checked: sw.checked
        property alias switchEnabled: sw.enabled

        signal toggled(bool value)

        width: parent.width
        spacing: Config.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: switchRow.label
        }

        StyledSwitch {
            id: sw

            onToggled: v => switchRow.toggled(v)
        }
    }

    component ActionButton: StyledRect {
        id: btn

        required property string glyph
        // Shows the spinner instead of the glyph (and blocks clicks)
        property bool busy
        // Blocks clicks only, keeping the glyph
        property bool disabled

        signal clicked

        Layout.preferredWidth: root.rowHeight
        Layout.minimumWidth: root.rowHeight
        Layout.preferredHeight: root.rowHeight
        radius: Config.rounding.small

        StyledText {
            anchors.centerIn: parent
            visible: !btn.busy
            text: btn.glyph
            font.pixelSize: Config.font.size.large
        }

        // Only spins while shown, so the glyphs never keep a stale rotation
        StyledText {
            id: spinner

            anchors.centerIn: parent
            visible: btn.busy
            text: Config.icons.loading
            font.pixelSize: Config.font.size.large

            RotationAnimator on rotation {
                running: spinner.visible
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }

        StateLayer {
            // The popup background is surface0, the StateLayer default
            color: Theme.text
            disabled: btn.busy || btn.disabled
            onClicked: btn.clicked()
        }
    }

    component DeviceRow: RowLayout {
        id: dev

        required property BluetoothDevice modelData

        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting || modelData.pairing

        // Unpaired: pair. Paired: toggle the connection.
        function toggleLink(): void {
            if (!modelData.paired)
                modelData.pair();
            else
                modelData.connected = !modelData.connected;
        }

        width: parent.width
        spacing: Config.spacing.small

        StyledText {
            Layout.preferredWidth: 24
            Layout.minimumWidth: 24
            horizontalAlignment: Text.AlignHCenter
            text: root.deviceGlyph(dev.modelData.icon)
            color: dev.modelData.connected ? Theme.active : dev.modelData.paired ? Theme.text : Theme.subtext0
            font.pixelSize: Config.font.size.large
        }

        StyledText {
            Layout.fillWidth: true
            text: dev.modelData.name
            color: dev.modelData.paired ? Theme.text : Theme.subtext0
            elide: Text.ElideRight
        }

        StyledText {
            visible: dev.modelData.batteryAvailable
            text: Math.round(dev.modelData.battery * 100) + "%"
            color: Theme.subtext0
        }

        // Trash goes left of the link button so the link column stays aligned
        // whether or not the device is paired
        ActionButton {
            visible: dev.modelData.paired
            glyph: Config.icons.trash
            // The whole row is inert while a connection or pairing is in flight
            disabled: dev.busy
            onClicked: dev.modelData.forget()
        }

        ActionButton {
            glyph: dev.modelData.connected ? Config.icons.linkOff : Config.icons.link
            busy: dev.busy
            onClicked: dev.toggleLink()
        }
    }
}
