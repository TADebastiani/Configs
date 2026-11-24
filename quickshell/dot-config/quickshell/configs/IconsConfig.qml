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

    // Bluetooth popout: device type glyphs (BlueZ theme icon names map to
    // these in BluetoothPopout.deviceGlyph) and row actions
    readonly property string btHeadset: String.fromCodePoint(0xF02CE)
    readonly property string btHeadphones: String.fromCodePoint(0xF02CB)
    readonly property string btSpeaker: String.fromCodePoint(0xF04C3)
    readonly property string btGamepad: String.fromCodePoint(0xF0297)
    readonly property string btKeyboard: String.fromCodePoint(0xF030C)
    readonly property string btMouse: String.fromCodePoint(0xF037D)
    readonly property string btTablet: String.fromCodePoint(0xF04F6)
    readonly property string btPhone: String.fromCodePoint(0xF011C)
    readonly property string btComputer: String.fromCodePoint(0xF0322)
    readonly property string btPrinter: String.fromCodePoint(0xF042A)
    readonly property string btCamera: String.fromCodePoint(0xF0100)

    readonly property string link: String.fromCodePoint(0xF0337)
    readonly property string linkOff: String.fromCodePoint(0xF0338)
    readonly property string trash: String.fromCodePoint(0xF01B4)
    readonly property string loading: String.fromCodePoint(0xF0772)

    // Session menu
    readonly property string power: String.fromCodePoint(0xF0425)
    readonly property string restart: String.fromCodePoint(0xF0709)
    readonly property string sleep: String.fromCodePoint(0xF04B2)
    readonly property string hibernate: String.fromCodePoint(0xF0717)
    readonly property string lock: String.fromCodePoint(0xF033E)
    readonly property string logout: String.fromCodePoint(0xF0343)
    readonly property string close: String.fromCodePoint(0xF0156)

    // OSD
    readonly property string brightness: String.fromCodePoint(0xF00E0)

    // Wi-Fi password dialog
    readonly property string eye: String.fromCodePoint(0xF0208)
    readonly property string eyeOff: String.fromCodePoint(0xF0209)
}
