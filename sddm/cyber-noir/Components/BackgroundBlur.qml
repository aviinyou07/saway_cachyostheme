// =============================================================================
// Blurred background layer -- ISOLATED ON PURPOSE
// =============================================================================
// QtGraphicalEffects is a Qt5-only module. SDDM 0.21 ships both a Qt5 and a Qt6
// greeter and currently launches the Qt5 one, so this resolves today. When that
// changes, a top-level `import QtGraphicalEffects` in Main.qml would fail and
// take the ENTIRE theme down with it -- SDDM would fall back to its default
// greeter and none of this design would ever render.
//
// Keeping the import in this leaf file means Main.qml loads it through a Loader:
// if the module is gone, only the blur is lost and the theme still comes up.
// See the fallback in Main.qml LAYER 1.
// =============================================================================
import QtQuick 2.15
import QtGraphicalEffects 1.15

FastBlur {
    property var sourceItem: null
    source: sourceItem
    radius: 24
    transparentBorder: false
}
