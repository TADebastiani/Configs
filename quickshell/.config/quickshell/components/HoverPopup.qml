pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.configs
import qs.components

// Popup that rises out from behind the bar, centered above `target`.
// The owner decides when it opens (`open`); this keeps "only one popup at a
// time" a decision of whoever holds several of them. `dismissRequested` fires
// when neither the target nor the popup is under the pointer anymore.
PopupWindow {
    id: popup

    required property Item target
    property bool targetHovered
    property bool open
    property Component content

    signal dismissRequested

    readonly property bool wantOpen: open && !!content

    // The content is built while the window is still unmapped, and the window
    // is only mapped once its size stopped changing. Otherwise it would show
    // up small and then reshape itself while the slide-in already runs.
    // Stays mapped while the slide-out runs.
    property bool ready

    visible: (wantOpen && ready) || slideOut.running
    color: "transparent"
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight

    // Centered above the target, resting on top of the bar window
    anchor {
        window: popup.target.QsWindow.window
        edges: Edges.Top
        gravity: Edges.Top

        // The target has no scene position yet when the popup is created
        onAnchoring: {
            const p = popup.target.mapToItem(null, 0, 0);
            popup.anchor.rect = Qt.rect(p.x, 0, popup.target.width, 1);
        }
    }

    // The popup lives in another window, so leaving the target doesn't mean the
    // pointer left the popup. Only dismiss if neither is hovered after a grace period.
    onTargetHoveredChanged: {
        if (targetHovered)
            closeTimer.stop();
        else
            closeTimer.restart();
    }

    Timer {
        id: closeTimer

        interval: 150
        onTriggered: {
            if (popup.open && !popup.targetHovered && !popupHover.hovered)
                popup.dismissRequested();
        }
    }

    // The window ends where the bar starts, so clipping here makes the popup
    // look like it rises out from behind the bar
    Item {
        id: slide

        // 1 = fully below the window edge (hidden), 0 = final position
        property real hidden: 1
        property int duration: 400

        anchors.fill: parent
        clip: true

        Anim {
            id: slideIn

            target: slide
            property: "hidden"
            to: 0
            type: Anim.Emphasized
            duration: slide.duration
            // Anim.Emphasized's own curve reaches 1 at 25% of the time
            easing.bezierCurve: Config.anim.emphasizedDecel
        }

        Anim {
            id: slideOut

            target: slide
            property: "hidden"
            to: 1
            type: Anim.Emphasized
            duration: slide.duration
            easing.bezierCurve: Config.anim.emphasizedAccel
        }

        StyledRect {
            id: background

            width: parent.width
            height: parent.height
            y: slide.hidden * height
            implicitWidth: contentLoader.implicitWidth + Config.padding.medium * 2
            implicitHeight: contentLoader.implicitHeight + Config.padding.large * 2
            color: Theme.surface0
            radius: Config.rounding.small

            HoverHandler {
                id: popupHover

                onHoveredChanged: {
                    if (hovered)
                        closeTimer.stop();
                    else
                        closeTimer.restart();
                }
            }

            // Recreated on each open so nothing survives a reopen
            Loader {
                id: contentLoader

                active: popup.wantOpen || popup.visible
                anchors.centerIn: parent
                sourceComponent: popup.content
            }
        }
    }

    Timer {
        id: settle

        interval: 50
        onTriggered: {
            popup.ready = true;
            slideIn.restart();
        }
    }

    Connections {
        target: background

        function onImplicitWidthChanged(): void {
            if (popup.wantOpen && !popup.ready)
                settle.restart();
        }

        function onImplicitHeightChanged(): void {
            if (popup.wantOpen && !popup.ready)
                settle.restart();
        }
    }

    // Both animations start from wherever the popup currently is, so a
    // hover during the slide-out reverses it instead of jumping
    onWantOpenChanged: {
        if (wantOpen) {
            slideOut.stop();
            if (visible)
                slideIn.restart();
            else
                settle.restart();
        } else {
            settle.stop();
            if (visible) {
                slideIn.stop();
                slideOut.restart();
            }
        }
    }

    onVisibleChanged: {
        if (!visible) {
            slideIn.stop();
            slideOut.stop();
            slide.hidden = 1;
            ready = false;
        }
    }
}
