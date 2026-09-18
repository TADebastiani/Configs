pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.configs
import qs.components

//import qs.modules.bar
//import qs.services

Item {
    id: root

    required property var bar
    property color color: Theme.active

    readonly property string windowTitle: {
        const title = ToplevelManager.activeToplevel?.title;
        //console.debug("[ActiveWindow.windowTitle] title", title);

        if (!title)
            return "";

        // if (BarConfig.activeWindow?.compact) {
        //     const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
        //     if (parts.length > 1)
        //         return parts[parts.length - 1].trim();
        // }
        return title;
    }

    readonly property int maxWidth: {
        const otherModules = bar.children.filter(c => c.entryId && c.item !== this && c.entryId !== "spacer");
        const otherWidth = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimWidth ?? curr.width), 0);
        const width = bar.width - otherWidth - bar.spacing * (bar.children.length - 1) - bar.hPadding * 2;
        if (width <= 0) 
            console.error("[ActiveWindow] invalid width");
        return width;
    }

    property Title current: text

    //clip: true // caution!
    implicitWidth: icon.impliciWidth + current.implictWidth + current.anchors.leftMargin
    implicitHeight: Math.max(icon.implicitHeight, current.implicitHeight)

    // For bar-popouts
    // Loader {
    //     asynchronous: tru
    //     anchors.fill: parent
    //     active: true // Configurable
    // }

    IconImage {
        id: icon

        visible: !!ToplevelManager.activeToplevel
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        //color: root.color
        implicitSize: 18
        source: Quickshell.iconPath(ToplevelManager.activeToplevel?.appId)
        //source: Quickshell.iconPath("kitty")
    }

    Title {
        id: text
        font.bold: true
        padding: icon.width + Config.padding.small
    }

    // Title {
    //     id: text2
    //     visible: false
    // }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        // Configure font
        elide: Qt.ElideRight
        elideWidth: root.maxWidth - icon.width

        onTextChanged: {
            const next = root.current // === text1 ? text2 : text1;
            next.text = elidedText;
            root.current.visible = false;
            next.visible = true;
            root.current = next;

            //console.debug("[ActiveWindow.TextMetrics]",ToplevelManager.activeToplevel.appId);
        }

        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitWidth {
        Anim {}
    }

    component Title: StyledText {}
}
