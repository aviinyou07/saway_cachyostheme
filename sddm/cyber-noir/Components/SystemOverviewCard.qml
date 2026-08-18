import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import "." as CyberComponents

/*
 * System Overview Studio Card Module for SDDM
 * Dynamically binds to real hardware and Linux OS telemetry fed from sddm-telemetry-update service.
 */
CyberComponents.GlassCard {
    id: overviewCard
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
        spacing: 12

        // Section Title Header
        Text {
            text: "> SYSTEM OVERVIEW"
            font.family: overviewCard.fontName
            font.pointSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: "#38BDF8" // Vibrant Cyan
            Layout.bottomMargin: 4
        }

        // Telemetry Row Builder
        component TelemetryRow: RowLayout {
            property string icon: ""
            property string iconColor: "#38BDF8"
            property string label: ""
            property string val: ""
            spacing: 12
            Layout.fillWidth: true
            
            Text {
                text: icon
                font.family: overviewCard.fontName
                font.pointSize: 13
                color: iconColor
                Layout.preferredWidth: 22
            }
            Text {
                text: label
                font.family: overviewCard.fontName
                font.pointSize: 11
                color: "#94A3B8" // Slate
                Layout.preferredWidth: 90
            }
            Text {
                text: val
                font.family: overviewCard.fontName
                font.pointSize: 11
                font.weight: Font.Medium
                color: "#F8FAFC" // Crisp White
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        TelemetryRow { icon: ""; iconColor: "#38BDF8"; label: "OS"; val: typeof config !== "undefined" && config.osName ? config.osName : "CachyOS Linux" }
        TelemetryRow { icon: "󰌽"; iconColor: "#A78BFA"; label: "Kernel"; val: typeof config !== "undefined" && config.kernelVersion ? config.kernelVersion : "Linux Kernel" }
        TelemetryRow { icon: "󰅐"; iconColor: "#22C55E"; label: "Uptime"; val: typeof config !== "undefined" && config.uptimeStr ? config.uptimeStr : "Active Boot" }
        TelemetryRow { icon: "󰏖"; iconColor: "#F472B6"; label: "Packages"; val: typeof config !== "undefined" && config.packageCount ? config.packageCount : "Installed PKGs" }
        TelemetryRow { icon: ">_"; iconColor: "#FBBF24"; label: "Shell"; val: typeof config !== "undefined" && config.shellName ? config.shellName : "zsh" }
        TelemetryRow { icon: "󰍹"; iconColor: "#818CF8"; label: "Resolution"; val: typeof Screen !== "undefined" ? Screen.width + " x " + Screen.height : "Display" }
        TelemetryRow { icon: "󰇄"; iconColor: "#38BDF8"; label: "Session"; val: typeof sessionModel !== "undefined" && sessionModel && sessionModel.rowCount() > 0 ? (sessionModel.data(sessionModel.index(0,0), Qt.DisplayRole) || "Sway (Wayland)") : "Sway (Wayland)" }
        
        Item { Layout.fillHeight: true }
    }
}
