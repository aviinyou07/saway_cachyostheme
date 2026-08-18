import QtQuick 2.15
import QtQuick.Layouts 1.15
import "." as CyberComponents

/*
 * Sway Wayland Studio Shortcuts Glass Card Module for SDDM
 * Displays authentic active workstation keybindings in sleek multi-colored Cyber Studio formatting.
 */
CyberComponents.GlassCard {
    id: shortcutsCard
    width: 372
    // Height follows the content. Hardcoded heights matched the rows exactly,
    // so the last row sat on the border and clipped as soon as any value
    // wrapped or a font metric differed.
    implicitHeight: content.implicitHeight + 36
    height: implicitHeight

    property string fontName: "JetBrainsMono Nerd Font"

    // Measured once from the longest hotkey string in the list below.
    TextMetrics {
        id: hotkeyMetrics
        font.family: shortcutsCard.fontName
        font.pointSize: 11
        font.weight: Font.Medium
        text: "Super + Sh + Spc"
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        spacing: 13

        Text {
            text: "> SWAY SHORTCUTS"
            font.family: shortcutsCard.fontName
            font.pointSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: "#38BDF8" // Vibrant Cyan
            Layout.bottomMargin: 2
        }

        component ShortcutRow: RowLayout {
            property string icon: ""
            property string iconColor: "#38BDF8"
            property string label: ""
            property string hotkey: ""
            spacing: 12
            Layout.fillWidth: true

            Text {
                text: icon
                font.family: shortcutsCard.fontName
                font.pointSize: 13
                color: iconColor
                Layout.preferredWidth: 22
            }
            Text {
                text: label
                font.family: shortcutsCard.fontName
                font.pointSize: 11
                color: "#E2E8F0"
                Layout.fillWidth: true
                // Without an elide the label just overflows and paints straight
                // through the hotkey column -- "Floating Toggle" collided with
                // "Super + Sh + Spc" at the previous card width.
                elide: Text.ElideRight
            }
            Text {
                text: hotkey
                font.family: shortcutsCard.fontName
                font.pointSize: 11
                font.weight: Font.Medium
                color: "#94A3B8"
                horizontalAlignment: Text.AlignRight
                // Reserve the widest hotkey so the right column never shifts
                // between rows and the label always knows how much room it has.
                Layout.preferredWidth: hotkeyMetrics.width
                Layout.minimumWidth: hotkeyMetrics.width
            }
        }

        ShortcutRow { icon: "󰆍"; iconColor: "#38BDF8"; label: "Terminal"; hotkey: "Super + T" }
        ShortcutRow { icon: "󰀻"; iconColor: "#A78BFA"; label: "App Launcher"; hotkey: "Super + D" }
        ShortcutRow { icon: "󰖲"; iconColor: "#818CF8"; label: "Floating Toggle"; hotkey: "Super + Sh + Spc" }
        ShortcutRow { icon: "󰊓"; iconColor: "#2DD4BF"; label: "Fullscreen Zoom"; hotkey: "Super + F" }
        ShortcutRow { icon: "󰋋"; iconColor: "#F472B6"; label: "Scratchpad"; hotkey: "Super + Minus" }
        ShortcutRow { icon: "󰅙"; iconColor: "#EF4444"; label: "Close Window"; hotkey: "Super + Sh + Q" }

        Item { Layout.fillHeight: true }
    }
}
