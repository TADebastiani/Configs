pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.configs
import qs.components
import qs.components.containers
import qs.services

// Asks for the password of a Wi-Fi network, in the center of the focused screen.
// Stays open until it connects or is cancelled: a click outside does nothing, so
// a stray click can't throw away what was typed.
StyledWindow {
    id: root

    // Stays mapped while the fade-out runs
    property bool mapped
    // 0 = hidden, 1 = fully shown
    property real shownAmount
    property bool revealPassword

    readonly property bool canSubmit: Network.isValidPassword(field.text) && !Network.passwordBusy

    function submit(): void {
        if (canSubmit)
            Network.submitPassword(field.text);
    }

    name: "network-password"
    visible: mapped
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Network.passwordOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Connections {
        target: Network

        function onPasswordOpenChanged(): void {
            // The password doesn't outlive the dialog
            field.clear();
            root.revealPassword = false;

            if (Network.passwordOpen) {
                fadeOut.stop();
                root.mapped = true;
                field.forceActiveFocus();
                fadeIn.restart();
            } else {
                fadeIn.stop();
                fadeOut.restart();
            }
        }

        function onPasswordErrorChanged(): void {
            if (Network.passwordError !== "") {
                field.selectAll();
                field.forceActiveFocus();
            }
        }
    }

    Anim {
        id: fadeIn

        target: root
        property: "shownAmount"
        to: 1
        type: Anim.FastEffects
    }

    Anim {
        id: fadeOut

        target: root
        property: "shownAmount"
        to: 0
        type: Anim.FastEffects
        onFinished: root.mapped = false
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.4 * root.shownAmount
    }

    // Keeps the pointer's clicks and hover away from anything underneath
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    StyledRect {
        id: card

        anchors.centerIn: parent
        implicitWidth: Config.sizes.networkDialogWidth
        implicitHeight: content.implicitHeight + Config.padding.large * 2
        opacity: root.shownAmount
        color: Theme.surface0
        radius: Config.rounding.small

        ColumnLayout {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Config.padding.large
                rightMargin: Config.padding.large
            }
            spacing: Config.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: Network.passwordName
                font.pixelSize: Config.font.size.large
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Esta rede pede senha")
                color: Theme.subtext0
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 36
                color: Theme.base
                radius: Config.rounding.small
                border.width: 1
                border.color: field.activeFocus ? Theme.active : Theme.surface2

                TextInput {
                    id: field

                    anchors {
                        left: parent.left
                        right: revealButton.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: Config.padding.medium
                        rightMargin: Config.spacing.small
                    }
                    clip: true
                    readOnly: Network.passwordBusy
                    echoMode: root.revealPassword ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    color: Theme.text
                    selectionColor: Theme.active
                    selectedTextColor: Theme.base
                    font.family: Config.font.family
                    font.pixelSize: Config.font.size.small

                    onAccepted: root.submit()
                    Keys.onEscapePressed: Network.cancelPassword()

                    StyledText {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Senha")
                        color: Theme.overlay0
                    }
                }

                StyledRect {
                    id: revealButton

                    anchors {
                        right: parent.right
                        rightMargin: 2
                        verticalCenter: parent.verticalCenter
                    }
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Config.rounding.small

                    StyledText {
                        anchors.centerIn: parent
                        text: root.revealPassword ? Config.icons.eyeOff : Config.icons.eye
                        color: Theme.subtext0
                        font.pixelSize: Config.font.size.large
                    }

                    StateLayer {
                        color: Theme.text
                        onClicked: root.revealPassword = !root.revealPassword
                    }
                }
            }

            StyledText {
                visible: Network.passwordError !== ""
                Layout.fillWidth: true
                text: Network.passwordError
                color: Theme.red
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Config.spacing.small
                spacing: Config.spacing.small

                Item {
                    Layout.fillWidth: true
                }

                DialogButton {
                    label: qsTr("Cancelar")
                    onClicked: Network.cancelPassword()
                }

                DialogButton {
                    label: Network.passwordBusy ? qsTr("Conectando...") : qsTr("Conectar")
                    primary: true
                    disabled: !root.canSubmit
                    onClicked: root.submit()
                }
            }
        }
    }

    component DialogButton: StyledRect {
        id: button

        required property string label
        property bool primary
        property bool disabled

        signal clicked

        implicitWidth: buttonText.implicitWidth + Config.padding.large * 2
        implicitHeight: 32
        radius: Config.rounding.small
        color: primary ? Theme.active : Theme.surface1
        opacity: disabled ? 0.5 : 1

        StyledText {
            id: buttonText

            anchors.centerIn: parent
            text: button.label
            color: button.primary ? Theme.base : Theme.text
        }

        StateLayer {
            color: button.primary ? Theme.base : Theme.text
            disabled: button.disabled
            onClicked: button.clicked()
        }
    }
}
