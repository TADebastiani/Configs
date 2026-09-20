pragma ComponentBehavior: Bound

import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.configs
import qs.components
import qs.services

RowLayout {
    id: root

    required property ShellScreen screen

    default property int hPadding: Config.padding.large

    spacing: Config.spacing.medium
    implicitWidth: screen.width
    anchors.fill: parent

    Repeater {
        id: repeater
        model: {
            values: Config.bar.entries.filter(e => e.enabled);
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    Layout.fillWidth: true
                }
            }

            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    Workspaces {
                        objectName: "taskbarWorkspaces"
                    }
                }
            }

            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    ActiveWindow {
                        objectName: "taskbarActiveWindow"
                        bar: root
                    }
                }
            }

            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {}
                }
            }

            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    Tray {
                        objectName: "taskbarTray"
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        Layout.leftMargin: index === 0 ? root.hPadding : 0
        Layout.rightMargin: index === repeater.count - 1 ? root.hPadding : 0
        Layout.topMargin: {
            return 0;
        }
        Layout.alignment: Qt.AlignVCenter

        //anchors.left: parent.left

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
