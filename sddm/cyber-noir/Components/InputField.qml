import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/*
 * Customized Universal Studio Input Field Module for SDDM
 * Supports Username and Password modes with interactive focus animations matching Waybar.
 */
Item {
    id: inputContainer
    height: 48

    property string fontName: "JetBrainsMono Nerd Font"
    property string colorBorderDefault: "#2038BDF8"
    property string colorBorderFocus: "#38BDF8"
    property string colorBg: "#111827"
    property string colorText: "#F8FAFC"
    property string colorPlaceholder: "#64748B"
    property string colorError: "#FF5252"
    property bool hasError: false
    property bool isPassword: true
    property string leftIcon: "󰌆"
    property string placeholder: "Password"
    property bool revealPassword: false
    property alias text: textField.text
    property alias inputFocus: textField.focus
    property alias isFocused: textField.activeFocus
    signal accepted()
    function setFocus() { textField.forceActiveFocus() }

    // Outer glow simulation when actively focused
    Rectangle {
        id: glowBox
        anchors.fill: parent
        anchors.margins: textField.activeFocus ? -3 : 0
        radius: 14
        color: "transparent"
        border.color: inputContainer.hasError ? inputContainer.colorError : 
                     (textField.activeFocus ? inputContainer.colorBorderFocus : "transparent")
        border.width: textField.activeFocus ? 1 : 0
        opacity: textField.activeFocus ? 0.35 : 0.0

        Behavior on anchors.margins { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    }

    // Main Input Card Body
    Rectangle {
        id: inputCard
        anchors.fill: parent
        radius: 12
        color: inputContainer.colorBg
        border.color: inputContainer.hasError ? inputContainer.colorError :
                     (textField.activeFocus ? inputContainer.colorBorderFocus : inputContainer.colorBorderDefault)
        border.width: textField.activeFocus ? 1.5 : 1.0

        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            // Left Icon Display
            Text {
                text: inputContainer.leftIcon
                font.family: inputContainer.fontName
                font.pointSize: 15
                color: inputContainer.hasError ? inputContainer.colorError :
                      (textField.activeFocus ? "#38BDF8" : "#64748B")

                Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            // Real text input control
            TextInput {
                id: textField
                Layout.fillWidth: true
                font.family: inputContainer.fontName
                font.pointSize: 13
                color: inputContainer.colorText
                echoMode: (inputContainer.isPassword && !inputContainer.revealPassword) ? TextInput.Password : TextInput.Normal
                passwordCharacter: "●"
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                clip: true

                onAccepted: inputContainer.accepted()

                // Placeholder display
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: inputContainer.placeholder
                    font: textField.font
                    color: inputContainer.colorPlaceholder
                    visible: !textField.text && !textField.activeFocus
                }
            }
        }
    }
}
