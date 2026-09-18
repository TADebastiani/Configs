pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs
import qs.configs
import qs.components
import qs.services

StackView {
    id: root

    required property PopoutState popouts
    required property QsMenuHandle trayItem

    implicitHeight: currentItem?.implicitHeight ?? 0
    implicitWidth: currentItem?.implicitWidth ?? 0

    initialItem: SubMenu {
        handle: root.trayItem
    }

    pushEnter: NoAnim {}
    pushExit: NoAnim {}
    popEnter: NoAnim {}
    popExit: NoAnim {}

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    component SubMenu: Column {
        id: menu

        required property QsMenuHandle handle
        property bool isSubMenu
        property bool shown

        padding: Config.padding.small
        spacing: Config.spacing.small

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.8

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        QsMenuOpener {
            id: menuOpener
            menu: menu.handle
        }

        Repeater {
            model: menuOpener.children

            StyledRect {
                id: item

                required property QsMenuEntry modelData

                implicitWidth: Config.sizes.bar.trayMenuWidth
                implicitHeight: modelData.isSeparator ? 1 : children.implicitHeight

                radius: Config.rounding.large
                color: modelData.isSeparator ? Theme.overlay0 : "transparent"

                Loader {
                    id: children

                    asynchronous: true
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    active: !item.modelData.isSeparator

                    sourceComponent: Item {
                        implicitHeight: label.implicitHeight

                        StateLayer {
                            anchors {
                                margins: Config.padding.extraSmall / 2
                                leftMargin: -Config.padding.small
                                rightMargin: -Config.padding.small
                            }

                            radius: item.radius
                            disabled: !item.modelData.enabled

                            onClicked: {
                                const entry = item.modelData;
                                if (entry.hasChildren) {
                                    root.push(subMenuComp.createObject(null, {
                                        handle: entry,
                                        isSubMenu: true
                                    }));
                                } else {
                                    item.modelData.triggered();
                                    root.popouts.hasCurrent = false;
                                }
                            }
                        }

                        Loader {
                            id: icon

                            asynchronous: true
                            anchors.left: parent.left
                            active: item.modelData.icon !== ""

                            sourceComponent: IconImage {
                                asynchronous: true
                                implicitSize: label.implicitHeight
                                source: item.modelData.icon
                            }
                        }

                        StyledText {
                            id: label

                            anchors {
                                left: icon.right
                                leftMargin: icon.active ? Config.spacing.medium : 0
                            }
                            text: labelMetrics.elidedText
                            color: item.modelData.enabled ? Theme.text : Theme.subtext0
                        }

                        TextMetrics {
                            id: labelMetrics

                            text: item.modelData.text
                            //font

                            elide: Text.ElideRight
                            elideWidth: {
                                const iconSize = icon.active ? icon.implicitWidth + label.anchors.leftMargin : 0;
                                const expandSize = expand.active ? expand.implicitWidth + Config.spacing.medium : 0;

                                return Config.sizes.bar.trayMenuWidth - iconSize - expandSize;
                            }
                        }

                        Loader {
                            id: expand

                            asynchronous: true
                            anchors {
                                verticalCenter: parent.verticalCenter
                                right: parent.right
                            }

                            active: item.modelData.hasChildren

                            sourceComponent: IconImage {
                                source: Quickshell.iconPath("chevron-right")
                            }
                        }
                    }
                }
            }
        }

        Loader {
            asynchronous: true
            active: menu.isSubMenu

            sourceComponent: Item {
                implicitWidth: back.implicitWidth
                implicitHeight: back.implicitHeight + Config.spacing.extraSmall

                Item {
                    anchors.bottom: parent.bottom
                    implicitWidth: back.implicitWidth
                    implicitHeight: back.implicitHeight

                    StyledRect {
                        anchors {
                            fill: parent
                            margins: -Config.padding.extraSmall / 2
                            leftMargin: -Config.padding.small
                            rightMargin: -Config.padding.large
                        }
                        radius: Config.rounding.large
                        color: Theme.surface1

                        StateLayer {
                            radius: parent.radius
                            color: Theme.surface2
                            onClicked: root.pop()
                        }
                    }

                    Row {
                        id: back
                        anchors.verticalCenter: parent.verticalCenter

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Quickshell.iconPath("chevron-left")
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Voltar")
                            color: Theme.lavender
                        }
                    }
                }
            }
        }
    }
}
