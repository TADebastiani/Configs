import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import qs
import qs.components

// A single top bar for one screen: i3 workspaces on the left,
// system status + clock on the right.
PanelWindow {
    id: bar

    readonly property string windowTitle: {
        const title = Hyprland.activeToplevel?.title;
        if (!title) {
            return qsTr("Desktop");
        }
        return title;
    }
    property Text current: text1

    // Variants (see shell.qml) instantiates one Bar per screen and needs
    // this property to feed each instance its `modelData` (a QuickshellScreenInfo).
    required property var modelData
    screen: modelData

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent" // the Rectangle below draws the real background

    Rectangle {
        anchors.fill: parent
        color: Theme.base

        // hairline to separate the bar from the rest of the screen
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.crust
        }
    }

    // ---------------------------------------------------------------
    // Left: workspaces
    // ---------------------------------------------------------------
    RowLayout {
        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 6

        OldWorkspaces {}
    }

    RowLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        Text {
            id: metrics
            text: bar.windowTitle
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.subtext1
        }
    }

    // ---------------------------------------------------------------
    // Right: bluetooth, wifi, audio, clock
    // ---------------------------------------------------------------
    RowLayout {
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 8

        // --- Bluetooth --------------------------------------------------
        Rectangle {
            id: btPill
            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property int connectedCount: adapter ? adapter.devices.values.filter(d => d.connected).length : 0

            implicitWidth: btRow.implicitWidth + 16
            implicitHeight: 22
            radius: Theme.pillRadius
            color: Theme.surface0

            RowLayout {
                id: btRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰂯 "
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    color: btPill.adapter && btPill.adapter.enabled ? Theme.blue : Theme.overlay0
                }

                Text {
                    visible: btPill.connectedCount > 0
                    text: btPill.connectedCount
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.text
                }
            }
        }

        // --- Wifi ---------------------------------------------------------
        Rectangle {
            id: wifiPill
            readonly property var device: {
                for (const d of Networking.devices.values) {
                    if (d.type === DeviceType.Wifi)
                        return d;
                }
                return null;
            }
            readonly property var activeNetwork: {
                if (!device)
                    return null;
                for (const n of device.networks.values) {
                    if (n.connected)
                        return n;
                }
                return null;
            }

            implicitWidth: wifiRow.implicitWidth + 16
            implicitHeight: 22
            radius: Theme.pillRadius
            color: Theme.surface0

            RowLayout {
                id: wifiRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "📶" // 📶
                    font.pixelSize: Theme.fontSize - 1
                    opacity: wifiPill.activeNetwork ? 1 : 0.4
                }

                Text {
                    text: wifiPill.activeNetwork ? wifiPill.activeNetwork.name : "Offline"
                    font.pixelSize: Theme.fontSize - 2
                    color: wifiPill.activeNetwork ? Theme.text : Theme.overlay0
                    elide: Text.ElideRight
                    Layout.maximumWidth: 120
                }
            }
        }

        // --- Audio ----------------------------------------------------
        Audio {}
        // --- Clock ------------------------------------------------------
        Clock {}
    }
}
