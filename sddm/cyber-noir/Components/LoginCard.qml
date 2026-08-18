import QtQuick 2.15
import QtQuick.Layouts 1.15
import "." as CyberComponents

/*
 * Main Cyber Studio Glass Dashboard Login Card Module
 * Cleanly optimized: zero redundant labels, zero dummy controls, 100% reactive & working buttons.
 */
CyberComponents.GlassCard {
    id: loginCard
    width: 490
    height: 680
    activeGlow: true

    property string fontName: "JetBrainsMono Nerd Font"
    property string targetUser: ""   // supplied by Main.qml from SDDM's userModel
    property bool isAuthenticating: false

    signal submitLogin(string pass)

    function focusPassword() {
        passInput.setFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 36
        spacing: 16

        Text {
            text: "</>"
            font.family: loginCard.fontName
            font.pointSize: 24
            font.weight: Font.Bold
            color: "#38BDF8" // Vibrant Cyan
            Layout.alignment: Qt.AlignHCenter
        }

        CyberComponents.Clock {
            Layout.alignment: Qt.AlignHCenter
        }

        Item { height: 4 }

        CyberComponents.UserAvatar {
            Layout.alignment: Qt.AlignHCenter
            username: loginCard.targetUser
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            // Clean username display
            Text {
                text: loginCard.targetUser !== "" ? loginCard.targetUser : "Sign in"
                font.family: loginCard.fontName
                font.pointSize: 19
                font.weight: Font.Bold
                color: "#F8FAFC"
                Layout.alignment: Qt.AlignHCenter
                renderType: Text.NativeRendering
            }
            Text {
                text: "Developer Workstation"
                font.family: loginCard.fontName
                font.pointSize: 11
                font.weight: Font.Medium
                color: "#38BDF8" // Vibrant Cyan
                Layout.alignment: Qt.AlignHCenter
                renderType: Text.NativeRendering
            }
        }

        Item { height: 10 }

        CyberComponents.InputField {
            Layout.fillWidth: true
            isPassword: false
            leftIcon: "󰀉"
            placeholder: "Username"
            text: loginCard.targetUser
        }

        CyberComponents.InputField {
            id: passInput
            Layout.fillWidth: true
            isPassword: true
            leftIcon: "󰌆"
            placeholder: "Password"
            onAccepted: loginCard.submitLogin(text)
        }

        Item { height: 8 }

        // Vibrant Cyan LOGIN Button (100% functional authentication execution)
        Rectangle {
            id: loginBtn
            Layout.fillWidth: true
            height: 52
            radius: 12
            color: loginArea.pressed ? "#0284C7" : "#38BDF8"
            scale: loginArea.pressed ? 0.98 : 1.0

            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: loginCard.isAuthenticating ? "AUTHENTICATING..." : "LOGIN"
                font.family: loginCard.fontName
                font.pointSize: 15
                font.weight: Font.Bold
                font.letterSpacing: 2.0
                color: "#0F172A" // Deep Obsidian Navy for maximum contrast
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁔"
                font.family: loginCard.fontName
                font.pointSize: 18
                font.weight: Font.Bold
                color: "#0F172A"
                visible: !loginCard.isAuthenticating
            }

            MouseArea {
                id: loginArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: loginCard.submitLogin(passInput.text)
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Text {
                text: "󰌾"
                font.family: loginCard.fontName
                font.pointSize: 12
                color: "#38BDF8"
            }
            Text {
                text: "Secure Login   •   Encrypted   •   Local Authentication"
                font.family: loginCard.fontName
                font.pointSize: 9
                color: "#94A3B8"
            }
        }
    }

    Component.onCompleted: {
        passInput.setFocus()
    }
}
