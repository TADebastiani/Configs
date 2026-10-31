pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Network state for the status icon (wired wins over Wi-Fi) and the Wi-Fi
// actions of the network popout and the password dialog.
Singleton {
    id: root

    readonly property var devices: [...Networking.devices.values]

    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected && d.hasLink) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNetwork: wifi ? ([...wifi.networks.values].find(n => n.connected) ?? null) : null

    // The Wi-Fi adapter, connected or not. Hidden networks have no name to show.
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: wifiDevice ? [...wifiDevice.networks.values].filter(n => n.name !== "") : []

    // 0..1
    readonly property real strength: wifiNetwork?.signalStrength ?? 0
    readonly property bool connected: wired !== null || wifi !== null

    readonly property string icon: {
        if (wired)
            return Config.icons.ethernet;
        if (!wifi)
            return Config.icons.wifiOff;
        return signalIcon(strength);
    }

    // The popout scans only while it is open
    property bool scanRequested

    // The connection attempt being followed. Its signals say how it ended.
    property var pending: null
    property bool pendingWasKnown
    // Shown on the network's row until the popout closes
    property string failedName

    // Password dialog: it is open while passwordName is set. The network itself
    // can vanish while the dialog is open, so its name is kept apart.
    property var passwordNetwork: null
    property string passwordName
    property string passwordError
    property bool passwordWasKnown
    readonly property bool passwordOpen: passwordName !== ""
    readonly property bool passwordBusy: passwordOpen && pending !== null

    function signalIcon(value: real): string {
        if (value >= 0.8)
            return Config.icons.wifi4;
        if (value >= 0.6)
            return Config.icons.wifi3;
        if (value >= 0.4)
            return Config.icons.wifi2;
        if (value >= 0.2)
            return Config.icons.wifi1;
        return Config.icons.wifi0;
    }

    // The only types connectWithPsk accepts
    function usesPassword(network: var): bool {
        return network.security === WifiSecurityType.WpaPsk || network.security === WifiSecurityType.Wpa2Psk || network.security === WifiSecurityType.Sae;
    }

    function isSecured(network: var): bool {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    // Enterprise and WEP networks need more than the password dialog asks for.
    // One that is already saved still connects with what NetworkManager has.
    function canConnect(network: var): bool {
        if (network.known || usesPassword(network))
            return true;
        return !isSecured(network) || network.security === WifiSecurityType.Unknown;
    }

    // WPA takes 8-63 characters or 64 hex digits. NetworkManager refuses anything
    // else without any signal, so these never leave the dialog. SAE has no such rule.
    function isValidPassword(text: string): bool {
        if (passwordNetwork?.security === WifiSecurityType.Sae)
            return text.length > 0;
        return (text.length >= 8 && text.length <= 63) || /^[0-9a-fA-F]{64}$/.test(text);
    }

    function activate(network: var): void {
        if (!network || network.connected || network.stateChanging || !canConnect(network))
            return;

        failedName = "";
        if (!network.known && usesPassword(network)) {
            openPassword(network, "");
            return;
        }

        follow(network);
        network.connect();
    }

    function submitPassword(password: string): void {
        const network = passwordNetwork;
        if (!network) {
            passwordError = qsTr("A rede saiu de alcance");
            return;
        }
        if (passwordBusy || !isValidPassword(password))
            return;

        passwordError = "";
        follow(network);
        network.connectWithPsk(password);
    }

    // A failed attempt on a new network leaves a NetworkManager profile behind.
    // It stays for the retries and goes away here, so that nothing gets saved.
    function cancelPassword(): void {
        if (!passwordWasKnown && passwordNetwork?.known)
            passwordNetwork.forget();
        pending = null;
        timeout.stop();
        closePassword();
    }

    function openPassword(network: var, error: string): void {
        passwordNetwork = network;
        passwordWasKnown = network.known;
        passwordError = error;
        passwordName = network.name;
    }

    function closePassword(): void {
        passwordName = "";
        passwordError = "";
        passwordNetwork = null;
    }

    function follow(network: var): void {
        pending = network;
        pendingWasKnown = network.known;
        timeout.restart();
    }

    function failureMessage(reason: int): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
        case ConnectionFailReason.WifiClientDisconnected:
            return qsTr("Senha incorreta");
        case ConnectionFailReason.WifiAuthTimeout:
            return qsTr("A rede demorou para responder");
        case ConnectionFailReason.WifiNetworkLost:
            return qsTr("A rede saiu de alcance");
        default:
            return qsTr("Não foi possível conectar");
        }
    }

    function handleFailure(reason: int): void {
        const network = pending;
        const wasKnown = pendingWasKnown;
        const name = network?.name ?? "";
        pending = null;
        timeout.stop();

        if (passwordOpen) {
            passwordError = failureMessage(reason);
            return;
        }

        // A saved network whose password changed
        if (network && reason === ConnectionFailReason.NoSecrets && usesPassword(network)) {
            openPassword(network, qsTr("A senha salva não funcionou"));
            return;
        }

        failedName = name;
        if (!wasKnown && network?.known)
            network.forget();
    }

    Binding {
        when: root.wifiDevice !== null
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.scanRequested
    }

    Connections {
        target: root.pending

        function onConnectedChanged(): void {
            if (!root.pending?.connected)
                return;

            root.pending = null;
            timeout.stop();
            root.closePassword();
        }

        function onConnectionFailed(reason: int): void {
            root.handleFailure(reason);
        }
    }

    // Only some failures raise connectionFailed, and a network that vanishes
    // raises nothing at all
    Timer {
        id: timeout

        interval: 60000
        onTriggered: root.handleFailure(ConnectionFailReason.Unknown)
    }
}
