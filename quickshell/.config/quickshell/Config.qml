pragma Singleton

import QtQuick
import Quickshell
import qs.configs

// Each section lives in its own file under configs/ and is exposed through a
// *typed* property, so qmlls/qmllint can resolve `Config.border.thickness`.
// (A `property QtObject x: QtObject { ... }` would type it as a bare QtObject,
// which has no members and makes the LSP report "Member not found".)
Singleton {
    readonly property AnimConfig anim: AnimConfig {}
    readonly property SpacingConfig spacing: SpacingConfig {}
    readonly property PaddingConfig padding: PaddingConfig {}
    readonly property RoundingConfig rounding: RoundingConfig {}
    readonly property SizesConfig sizes: SizesConfig {}
    readonly property BorderConfig border: BorderConfig {}
    readonly property BarConfig bar: BarConfig {}
}
