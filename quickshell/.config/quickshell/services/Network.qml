pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Network state for the status icon. Wired wins over Wi-Fi.
Singleton {
    id: root

    readonly property var devices: [...Networking.devices.values]

    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected && d.hasLink) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNetwork: wifi ? ([...wifi.networks.values].find(n => n.connected) ?? null) : null

    // 0..1
    readonly property real strength: wifiNetwork?.signalStrength ?? 0
    readonly property bool connected: wired !== null || wifi !== null

    readonly property string icon: {
        if (wired)
            return Config.icons.ethernet;
        if (!wifi)
            return Config.icons.wifiOff;
        if (strength >= 0.8)
            return Config.icons.wifi4;
        if (strength >= 0.6)
            return Config.icons.wifi3;
        if (strength >= 0.4)
            return Config.icons.wifi2;
        if (strength >= 0.2)
            return Config.icons.wifi1;
        return Config.icons.wifi0;
    }
}
