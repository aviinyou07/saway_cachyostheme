import QtQuick 2.15
import QtQuick.Layouts 1.15
import "." as CyberComponents

/*
 * Cyber Studio Philosophy Card Module for SDDM
 * Features prominent developer typography matching the modular obsidian Waybar aesthetic.
 */
CyberComponents.GlassCard {
    id: quoteCard
    width: 372
    // Height follows the content. Hardcoded heights matched the rows exactly,
    // so the last row sat on the border and clipped as soon as any value
    // wrapped or a font metric differed.
    implicitHeight: content.implicitHeight + 36
    height: implicitHeight

    property string fontName: "JetBrainsMono Nerd Font"

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        spacing: 8

        Text {
            text: "> QUOTE"
            font.family: quoteCard.fontName
            font.pointSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: "#38BDF8" // Vibrant Cyan
        }

        Text {
            text: "“"
            font.family: quoteCard.fontName
            font.pointSize: 22
            font.weight: Font.Bold
            color: "#38BDF8"
            Layout.topMargin: 2
            Layout.bottomMargin: -12
        }

        Text {
            text: "Simplicity is prerequisite for reliability. Design must be functional and state of the art."
            font.family: quoteCard.fontName
            font.pointSize: 11
            color: "#E2E8F0"
            lineHeight: 1.3
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Text {
            text: "- Edsger W. Dijkstra"
            font.family: quoteCard.fontName
            font.pointSize: 11
            font.weight: Font.Medium
            color: "#38BDF8"
            Layout.topMargin: 4
        }
        
        Item { Layout.fillHeight: true }
    }
}
