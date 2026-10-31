pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.configs
import qs.components
import qs.components.containers
import qs.services

// Icon rail on the right edge of the focused screen. The window covers the
// whole screen, without drawing anything, so a click outside the rail closes it.
StyledWindow {
    id: root

    readonly property var actions: [
        {
            id: "poweroff",
            glyph: Config.icons.power,
            label: qsTr("Desligar")
        },
        {
            id: "reboot",
            glyph: Config.icons.restart,
            label: qsTr("Reiniciar")
        },
        {
            id: "suspend",
            glyph: Config.icons.sleep,
            label: qsTr("Suspender")
        },
        {
            id: "hibernate",
            glyph: Config.icons.hibernate,
            label: qsTr("Hibernar")
        },
        {
            id: "lock",
            glyph: Config.icons.lock,
            label: qsTr("Bloquear tela"),
            separated: true
        },
        {
            id: "logout",
            glyph: Config.icons.logout,
            label: qsTr("Sair da sessão")
        },
        {
            id: "cancel",
            glyph: Config.icons.close,
            label: qsTr("Cancelar"),
            separated: true
        }
    ]
    // Opens here so that a stray Enter can't power off the PC
    readonly property int cancelIndex: actions.length - 1

    property int currentIndex: cancelIndex
    // Stays mapped while the slide-out runs
    property bool mapped

    function isEnabled(index: int): bool {
        return actions[index].id !== "hibernate" || Session.canHibernate;
    }

    // Moves by `step`, wrapping around and skipping unavailable actions
    function moveCurrent(step: int): void {
        let i = currentIndex;
        do {
            i = (i + step + actions.length) % actions.length;
        } while (!isEnabled(i));
        currentIndex = i;
    }

    name: "session"
    visible: mapped
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Session.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Connections {
        target: Session

        function onOpenChanged(): void {
            if (Session.open) {
                Session.refresh();
                root.currentIndex = root.cancelIndex;
                input.pointerSeen = false;
                slideOut.stop();
                root.mapped = true;
                input.forceActiveFocus();
                slideIn.restart();
            } else {
                slideIn.stop();
                slideOut.restart();
            }
        }
    }

    Anim {
        id: slideIn

        target: rail
        property: "hidden"
        to: 0
        type: Anim.Emphasized
        duration: 400
        // Anim.Emphasized's own curve reaches 1 at 25% of the time
        easing.bezierCurve: Config.anim.emphasizedDecel
    }

    Anim {
        id: slideOut

        target: rail
        property: "hidden"
        to: 1
        type: Anim.Emphasized
        duration: 400
        easing.bezierCurve: Config.anim.emphasizedDecel
        onFinished: root.mapped = false
    }

    // One area for the whole screen. The rail slides in under a pointer that
    // isn't moving, and only real movement may change the highlighted action,
    // which a hover on each cell couldn't tell apart.
    MouseArea {
        id: input

        property bool pointerSeen
        property real lastX
        property real lastY
        property bool overAction

        function indexAt(x: real, y: real): int {
            for (let i = 0; i < cells.count; i++) {
                const cell = cells.itemAt(i).cell;
                const p = cell.mapFromItem(input, x, y);
                if (cell.contains(p))
                    return i;
            }
            return -1;
        }

        anchors.fill: parent
        hoverEnabled: true
        focus: true
        cursorShape: overAction ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPositionChanged: mouse => {
            const moved = pointerSeen && (mouse.x !== lastX || mouse.y !== lastY);
            pointerSeen = true;
            lastX = mouse.x;
            lastY = mouse.y;
            if (!moved)
                return;

            const i = indexAt(mouse.x, mouse.y);
            overAction = i >= 0 && root.isEnabled(i);
            if (overAction)
                root.currentIndex = i;
        }

        onClicked: mouse => {
            const i = indexAt(mouse.x, mouse.y);
            if (i >= 0) {
                if (root.isEnabled(i))
                    Session.run(root.actions[i].id);
            } else if (!rail.contains(rail.mapFromItem(input, mouse.x, mouse.y))) {
                Session.open = false;
            }
        }

        Keys.onEscapePressed: Session.open = false
        Keys.onUpPressed: root.moveCurrent(-1)
        Keys.onDownPressed: root.moveCurrent(1)
        Keys.onReturnPressed: Session.run(root.actions[root.currentIndex].id)
        Keys.onEnterPressed: Session.run(root.actions[root.currentIndex].id)
    }

    StyledRect {
        id: rail

        readonly property int padding: Config.padding.extraSmall
        readonly property int barHeight: Config.sizes.bar.innerHeight + Config.bar.verticalPadding * 2
        // 1 = past the screen edge (hidden), 0 = final position
        property real hidden: 1

        anchors {
            right: parent.right
            rightMargin: Config.spacing.medium - hidden * (width + Config.spacing.medium)
            verticalCenter: parent.verticalCenter
            // Centered on the area above the bar
            verticalCenterOffset: -barHeight / 2
        }
        implicitWidth: list.implicitWidth + (padding + border.width) * 2
        implicitHeight: list.implicitHeight + (padding + border.width) * 2
        color: Theme.base
        radius: Config.rounding.large
        border.width: Config.bar.borderWidth
        border.color: Theme.surface0

        Column {
            id: list

            anchors.centerIn: parent

            Repeater {
                id: cells

                model: root.actions

                Item {
                    id: entry

                    required property var modelData
                    required property int index

                    readonly property alias cell: cell
                    readonly property bool enabledAction: root.isEnabled(index)
                    readonly property bool current: root.currentIndex === index

                    implicitWidth: cell.implicitWidth
                    implicitHeight: cell.implicitHeight + cell.y

                    StyledRect {
                        visible: !!entry.modelData.separated
                        y: Config.spacing.extraSmall
                        x: Config.spacing.extraSmall
                        width: parent.width - x * 2
                        height: Config.bar.borderWidth
                        color: Theme.surface0
                    }

                    StyledRect {
                        id: cell

                        y: entry.modelData.separated ? Config.spacing.extraSmall * 2 + Config.bar.borderWidth : 0
                        implicitWidth: Config.sizes.sessionCellSize
                        implicitHeight: Config.sizes.sessionCellSize
                        color: entry.current ? Theme.surface0 : "transparent"
                        radius: Config.rounding.small

                        StyledText {
                            anchors.centerIn: parent
                            text: entry.modelData.glyph
                            color: !entry.enabledAction ? Theme.overlay0 : entry.current ? Theme.active : Theme.text
                            font.pixelSize: Config.font.size.large
                        }

                        // Lives outside the rail, to the left of the cell
                        StyledRect {
                            // Gone as soon as the menu closes, not after the slide-out
                            visible: entry.current && Session.open
                            anchors {
                                right: parent.left
                                rightMargin: Config.spacing.small + rail.padding + rail.border.width
                                verticalCenter: parent.verticalCenter
                            }
                            implicitWidth: tipText.implicitWidth + Config.padding.small * 2
                            implicitHeight: tipText.implicitHeight + Config.padding.extraSmall * 2
                            color: Theme.surface0
                            radius: Config.rounding.small

                            StyledText {
                                id: tipText

                                anchors.centerIn: parent
                                text: entry.modelData.label
                            }
                        }
                    }
                }
            }
        }
    }
}
