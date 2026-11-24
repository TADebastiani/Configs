pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.configs
import qs.components
import qs.components.containers
import qs.services

// Volume or brightness bar that rises out from behind the bar, at the bottom
// center of the focused screen. Only the keys open it: the volume ones through
// `qs ipc call osd volume` (watching Audio.volume would also fire for the popout
// slider) and the brightness ones through the Brightness service.
StyledWindow {
    id: root

    // Stays mapped while the slide-out runs
    property bool mapped
    property bool shown
    // What the bar is showing: "volume" or "brightness"
    property string kind: "volume"

    readonly property bool isBrightness: kind === "brightness"
    readonly property bool muted: !isBrightness && Audio.muted
    readonly property string icon: isBrightness ? Config.icons.brightness : Audio.volumeIcon
    readonly property real level: isBrightness ? Brightness.percent / 100 : Audio.volume

    function show(newKind: string): void {
        kind = newKind;
        hideTimer.restart();
        if (shown)
            return;

        shown = true;
        slideOut.stop();
        mapped = true;
        slideIn.restart();
    }

    function hide(): void {
        hideTimer.stop();
        if (!shown)
            return;

        shown = false;
        slideIn.stop();
        slideOut.restart();
    }

    name: "osd"
    visible: mapped
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: Config.sizes.osdWidth
    implicitHeight: Config.sizes.osdHeight
    // Clicks go through to whatever is underneath
    mask: Region {}

    // Left and right are free, so the compositor centers it horizontally
    anchors.bottom: true
    margins.bottom: Config.sizes.bar.innerHeight + Config.bar.verticalPadding * 2

    IpcHandler {
        target: "osd"

        function volume(): void {
            // Without an output there is nothing to show
            if (Audio.sink !== null)
                root.show("volume");
        }
    }

    Connections {
        target: Brightness

        function onAdjusted(): void {
            root.show("brightness");
        }

        function onFailed(): void {
            if (root.isBrightness)
                root.hide();
        }
    }

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.hide()
    }

    // The window ends where the bar starts, so clipping here makes the OSD
    // look like it rises out from behind the bar
    Item {
        id: slide

        // 1 = fully below the window edge (hidden), 0 = final position
        property real hidden: 1

        anchors.fill: parent
        clip: true

        Anim {
            id: slideIn

            target: slide
            property: "hidden"
            to: 0
            type: Anim.Emphasized
            duration: 400
            // Anim.Emphasized's own curve reaches 1 at 25% of the time
            easing.bezierCurve: Config.anim.emphasizedDecel
        }

        Anim {
            id: slideOut

            target: slide
            property: "hidden"
            to: 1
            type: Anim.Emphasized
            duration: 400
            easing.bezierCurve: Config.anim.emphasizedAccel
            onFinished: root.mapped = false
        }

        StyledRect {
            width: parent.width
            height: parent.height
            y: slide.hidden * height
            color: Theme.surface0
            topLeftRadius: Config.rounding.small
            topRightRadius: Config.rounding.small

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Config.padding.medium
                    rightMargin: Config.padding.medium
                }
                spacing: Config.spacing.small

                StyledText {
                    Layout.preferredWidth: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: root.icon
                    color: root.muted ? Theme.subtext0 : Theme.text
                    font.pixelSize: Config.font.size.large
                }

                StyledRect {
                    id: track

                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: height / 2
                    color: Theme.surface2

                    // Full above 100 %; the percentage shows the real value
                    StyledRect {
                        width: Math.max(0, Math.min(root.level, 1)) * track.width
                        height: parent.height
                        radius: parent.radius
                        color: root.muted ? Theme.overlay0 : Theme.active
                    }
                }

                StyledText {
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.level * 100) + "%"
                    color: root.muted ? Theme.subtext0 : Theme.text
                }
            }
        }
    }
}
