import QtQuick 2.15
import QtQuick.Controls 2.15

/*
 * Cyber Circuit Flanked Avatar Module for SDDM Studio Theme
 * Replicates futuristic motherboard PCB traces flanking a glowing vibrant cyan user avatar.
 */
Item {
    id: avatarContainer
    width: 380
    height: 110

    property int size: 96
    property string username: ""   // supplied by LoginCard -- never hardcode an account
    property string borderColor: "#38BDF8" // Vibrant Cyan
    property string backgroundColor: "#111827" // Deep obsidian studio slate
    property string textColor: "#38BDF8"
    property string fontName: "JetBrainsMono Nerd Font"

    // Left PCB Circuit Traces
    Item {
        anchors.right: avatarGroup.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 100; height: 50

        // Main horizontal trace
        Rectangle { width: 50; height: 2; color: "#38BDF8"; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; opacity: 0.75 }
        Rectangle { width: 6; height: 6; radius: 3; color: "#38BDF8"; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
        
        // Upper diagonal branch
        Rectangle { width: 28; height: 2; color: "#38BDF8"; anchors.right: parent.right; anchors.rightMargin: 35; anchors.top: parent.top; anchors.topMargin: 10; rotation: -25; opacity: 0.65 }
        Rectangle { width: 22; height: 2; color: "#38BDF8"; anchors.left: parent.left; anchors.top: parent.top; anchors.topMargin: 4; opacity: 0.65 }
        Rectangle { width: 5; height: 5; radius: 2.5; color: "#38BDF8"; anchors.left: parent.left; anchors.top: parent.top; anchors.topMargin: 2.5; opacity: 0.9 }

        // Lower diagonal branch
        Rectangle { width: 28; height: 2; color: "#38BDF8"; anchors.right: parent.right; anchors.rightMargin: 35; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; rotation: 25; opacity: 0.65 }
        Rectangle { width: 22; height: 2; color: "#38BDF8"; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; opacity: 0.65 }
        Rectangle { width: 5; height: 5; radius: 2.5; color: "#38BDF8"; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.bottomMargin: 2.5; opacity: 0.9 }
        
        // Extra micro dots
        Rectangle { width: 4; height: 4; radius: 2; color: "#38BDF8"; anchors.left: parent.left; anchors.leftMargin: 30; anchors.verticalCenter: parent.verticalCenter; opacity: 0.8 }
    }

    // Right PCB Circuit Traces
    Item {
        anchors.left: avatarGroup.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 100; height: 50

        // Main horizontal trace
        Rectangle { width: 50; height: 2; color: "#38BDF8"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; opacity: 0.75 }
        Rectangle { width: 6; height: 6; radius: 3; color: "#38BDF8"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }

        // Upper diagonal branch
        Rectangle { width: 28; height: 2; color: "#38BDF8"; anchors.left: parent.left; anchors.leftMargin: 35; anchors.top: parent.top; anchors.topMargin: 10; rotation: 25; opacity: 0.65 }
        Rectangle { width: 22; height: 2; color: "#38BDF8"; anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 4; opacity: 0.65 }
        Rectangle { width: 5; height: 5; radius: 2.5; color: "#38BDF8"; anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 2.5; opacity: 0.9 }

        // Lower diagonal branch
        Rectangle { width: 28; height: 2; color: "#38BDF8"; anchors.left: parent.left; anchors.leftMargin: 35; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; rotation: -25; opacity: 0.65 }
        Rectangle { width: 22; height: 2; color: "#38BDF8"; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; opacity: 0.65 }
        Rectangle { width: 5; height: 5; radius: 2.5; color: "#38BDF8"; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: 2.5; opacity: 0.9 }

        // Extra micro dots
        Rectangle { width: 4; height: 4; radius: 2; color: "#38BDF8"; anchors.right: parent.right; anchors.rightMargin: 30; anchors.verticalCenter: parent.verticalCenter; opacity: 0.8 }
    }

    // Center Glowing Avatar Ring Group
    Item {
        id: avatarGroup
        width: avatarContainer.size
        height: avatarContainer.size
        anchors.centerIn: parent

        // Outer vibrant cyan glowing aura
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: width / 2
            color: "transparent"
            border.color: "#4038BDF8"
            border.width: 3
            opacity: 0.85
        }

        // Circular background base
        Rectangle {
            id: avatarBg
            anchors.fill: parent
            radius: width / 2
            color: avatarContainer.backgroundColor
            border.color: avatarContainer.borderColor
            border.width: 2

            Behavior on border.color { ColorAnimation { duration: 300; easing.type: Easing.OutQuad } }

            // Vibrant cyan cyber user initial
            Text {
                anchors.centerIn: parent
                text: avatarContainer.username ? avatarContainer.username.charAt(0).toUpperCase() : "\uf007"
                font.family: avatarContainer.fontName
                font.pointSize: 42
                font.weight: Font.Bold
                color: avatarContainer.textColor
            }

            // Optional custom user icon overlay if bitmap provided in ~/.face
            Image {
                id: faceImage
                anchors.fill: parent
                anchors.margins: 2
                source: typeof sddm !== "undefined" && sddm && sddm.user ? "file://" + sddm.user.icon : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                clip: true
            }
        }
    }
}
