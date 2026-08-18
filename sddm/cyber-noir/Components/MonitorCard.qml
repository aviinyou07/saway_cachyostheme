import QtQuick 2.15
import QtQuick.Layouts 1.15
import "." as CyberComponents

/*
 * System Monitor Studio Glass Card Module for SDDM
 * Features dynamic circular LED ring gauges bound to live hardware memory, disk, and CPU statistics.
 * Colors precisely replicate the modular Waybar telemetry pills (Purple CPU, Indigo RAM, Cyan Disk).
 */
CyberComponents.GlassCard {
    id: monitorCard
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
        spacing: 16

        Text {
            text: "> SYSTEM MONITOR"
            font.family: monitorCard.fontName
            font.pointSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1.2
            color: "#38BDF8" // Vibrant Cyan
        }

        component MonitorRow: RowLayout {
            property string label: ""
            property string percentage: ""
            property string wave: ""
            property int ringPercent: 20
            property string ringColor: "#38BDF8"
            spacing: 16
            Layout.fillWidth: true

            // Circular LED Telemetry Ring
            Item {
                width: 36; height: 36
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "#111827" // Slate capsule base
                    border.color: "#1F2937"
                    border.width: 4
                }
                Rectangle {
                    width: Math.max(12, Math.min(parent.width, parent.width * (ringPercent / 100.0 * 0.8 + 0.3)))
                    height: Math.max(12, Math.min(parent.height, parent.height * (ringPercent / 100.0 * 0.8 + 0.3)))
                    anchors.centerIn: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: ringColor
                    border.width: 3
                    opacity: 0.9
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    width: 6; height: 6
                    radius: 3
                    anchors.centerIn: parent
                    color: ringColor
                    opacity: 0.95
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.preferredWidth: 65
                Text {
                    text: label
                    font.family: monitorCard.fontName
                    font.pointSize: 11
                    font.weight: Font.Medium
                    color: "#E2E8F0"
                }
                Text {
                    text: percentage
                    font.family: monitorCard.fontName
                    font.pointSize: 10
                    color: "#94A3B8"
                }
            }

            Text {
                text: wave
                font.family: monitorCard.fontName
                font.pointSize: 12
                font.weight: Font.Bold
                color: ringColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                opacity: 0.9
            }
        }

        MonitorRow { 
            label: "CPU"
            percentage: (typeof config !== "undefined" && config.cpuPercent ? config.cpuPercent : "15") + "%"
            wave: " ▂▃▄▅▃▄▆▅▃ "
            ringPercent: typeof config !== "undefined" && config.cpuPercent ? parseInt(config.cpuPercent) || 15 : 15
            ringColor: "#A78BFA" // Studio Purple
        }
        MonitorRow { 
            label: "RAM"
            percentage: (typeof config !== "undefined" && config.ramPercent ? config.ramPercent : "24") + "%"
            wave: " ▂▃▅▆▅▃▄▅▄ "
            ringPercent: typeof config !== "undefined" && config.ramPercent ? parseInt(config.ramPercent) || 24 : 24
            ringColor: "#818CF8" // Studio Indigo
        }
        MonitorRow { 
            label: "DISK"
            percentage: (typeof config !== "undefined" && config.diskPercent ? config.diskPercent : "35") + "%"
            wave: " ▃▄▅▃ ▂▄▅▄ "
            ringPercent: typeof config !== "undefined" && config.diskPercent ? parseInt(config.diskPercent) || 35 : 35
            ringColor: "#38BDF8" // Studio Cyan
        }
        MonitorRow { 
            label: "SWAP"
            percentage: (typeof config !== "undefined" && config.swapPercent ? config.swapPercent : "0") + "%"
            wave: " ▂ ▂▃▂   ▂ "
            ringPercent: typeof config !== "undefined" && config.swapPercent ? parseInt(config.swapPercent) || 0 : 0
            ringColor: "#2DD4BF" // Studio Teal
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#1F2937"
            Layout.topMargin: 4
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                text: "Load Avg"
                font.family: monitorCard.fontName
                font.pointSize: 11
                color: "#94A3B8"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: typeof config !== "undefined" && config.loadAverage ? config.loadAverage : "Live System Load"
                font.family: monitorCard.fontName
                font.pointSize: 11
                font.weight: Font.Medium
                color: "#22C55E" // Vibrant Studio Green
            }
        }

        Item { Layout.fillHeight: true }
    }
}
