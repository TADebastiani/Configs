import QtQuick

// Nerd Font (Material Design) glyphs used by the status icons.
// Swap any code point to change an icon; codes come from glyphnames.json.
QtObject {
    readonly property string volumeOff: String.fromCodePoint(0xF0581)
    readonly property string volumeLow: String.fromCodePoint(0xF057F)
    readonly property string volumeMedium: String.fromCodePoint(0xF0580)
    readonly property string volumeHigh: String.fromCodePoint(0xF057E)

    readonly property string micOff: String.fromCodePoint(0xF036D)
    readonly property string mic: String.fromCodePoint(0xF036C)

    readonly property string ethernet: String.fromCodePoint(0xF0200)
    readonly property string wifi4: String.fromCodePoint(0xF0928)
    readonly property string wifi3: String.fromCodePoint(0xF0925)
    readonly property string wifi2: String.fromCodePoint(0xF0922)
    readonly property string wifi1: String.fromCodePoint(0xF091F)
    readonly property string wifi0: String.fromCodePoint(0xF092F)
    readonly property string wifiOff: String.fromCodePoint(0xF092D)

    readonly property string bluetoothOff: String.fromCodePoint(0xF00B2)
    readonly property string bluetooth: String.fromCodePoint(0xF00AF)
    readonly property string bluetoothConnected: String.fromCodePoint(0xF00B1)
}
