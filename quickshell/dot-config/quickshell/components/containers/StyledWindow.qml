import Quickshell
import Quickshell.Wayland

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint disable uncreatable-type
    required property string name

    WlrLayershell.namespace: `tadebastiani-${name}`
    color: "transparent"

    // contentItem.Config.screen: screen.name
    // contentItem.Tokens.screen: screen.name
}
