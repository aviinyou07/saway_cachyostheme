import QtQuick 2.15

/*
 * Reusable Glassmorphic Cyber Studio Card Module for SDDM
 * Features translucent deep obsidian background and vibrant cyan borders matching Waybar.
 */
Rectangle {
    id: glassCard
    radius: 16
    color: "#B00B0F19" // Deep obsidian studio night glass
    border.color: "#2538BDF8" // Subtle vibrant cyan perimeter
    border.width: 1
    clip: false

    property bool activeGlow: false

    // Outer cyber glow simulating backlighting on high-end glass dashboards
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.margins: glassCard.activeGlow ? -4 : -2
        radius: parent.radius + (glassCard.activeGlow ? 4 : 2)
        color: "transparent"
        border.color: glassCard.activeGlow ? "#5038BDF8" : "#1538BDF8"
        border.width: glassCard.activeGlow ? 2 : 1
        opacity: glassCard.activeGlow ? 1.0 : 0.5

        Behavior on anchors.margins { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutQuad } }
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
    }
}
