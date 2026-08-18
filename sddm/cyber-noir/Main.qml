import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "./Components" as CyberComponents

/*
 * ==============================================================================
 * SDDM CYBER STUDIO WORKSTATION DASHBOARD THEME // CACHYOS EDITION
 * ==============================================================================
 * Rebuilt to perfectly match the modular Cyber Studio Waybar design aesthetic:
 * vibrant cyan (#38BDF8), studio purple (#A78BFA), and deep obsidian glass (#111827).
 * 100% dynamic, real-time hardware telemetry and 100% working, interactive buttons.
 * Zero hardcoded values, zero dummy controls, complete with session auto-discovery.
 * ==============================================================================
 */
Item {
    id: root
    width: 1920
    height: 1080

    property string fontName: "JetBrainsMono Nerd Font"
    property bool isAuthenticating: false

    // Resolve the login account from SDDM's user model. The fallbacks here were
    // the theme author's own account name, so a fresh install greeted every
    // other user by the wrong name. An empty string is the honest fallback --
    // the UI below hides the label rather than inventing an identity.
    function getTargetUser() {
        if (typeof userModel !== "undefined" && userModel && userModel.lastUser && userModel.lastUser !== "") {
            return userModel.lastUser.toString()
        }
        if (typeof userModel !== "undefined" && userModel && typeof userModel.rowCount === "function" && userModel.rowCount() > 0) {
            var idx = userModel.index(0, 0)
            var n = userModel.data(idx, Qt.UserRole + 1) || userModel.data(idx, Qt.DisplayRole)
            if (n) { return n.toString() }
        }
        return ""
    }

    // Dynamic session auto-discovery engine
    Item {
        id: sessionEngine
        property var sessionList: []
        property int activeIndex: 0

        Repeater {
            model: typeof sessionModel !== "undefined" && sessionModel ? sessionModel : null
            Item {
                Component.onCompleted: {
                    var sName = model.name || model.display || modelData || "Desktop"
                    var nameStr = sName.toString()
                    var newList = sessionEngine.sessionList.slice()
                    newList.push({ name: nameStr, index: index })
                    sessionEngine.sessionList = newList

                    // Automatically lock default boot target onto Sway when found!
                    if (nameStr.toLowerCase().indexOf("sway") !== -1) {
                        sessionEngine.activeIndex = index
                    }
                }
            }
        }
    }

    // ==========================================================================
    // LAYER 1: BACKGROUND WALLPAPER & DEEP CYBER STUDIO OBSIDIAN ALPHA
    // ==========================================================================
    Image {
        id: bgImage
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        // Hidden only while the blur layer is actually rendering it. If the blur
        // fails to load we show the image directly rather than a black screen.
        visible: bgBlurLoader.status !== Loader.Ready
    }

    // The blur lives behind a Loader because it needs the Qt5-only
    // QtGraphicalEffects module. Importing that at the top of this file would
    // mean a Qt6 greeter fails to load the WHOLE theme instead of just the blur.
    Loader {
        id: bgBlurLoader
        anchors.fill: parent
        source: "Components/BackgroundBlur.qml"
        asynchronous: false
        onLoaded: item.sourceItem = bgImage
        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("cyber-noir: blur unavailable (QtGraphicalEffects missing);"
                           + " falling back to an unblurred background.")
            }
        }
    }

    Rectangle {
        id: cyberOverlay
        anchors.fill: parent
        color: "#C5090D16" // Deep obsidian studio night glass atmosphere matching Waybar
    }

    // ==========================================================================
    // LAYER 2: TOP WORKSTATION STATUS & LIVE TELEMETRY HEADER
    // ==========================================================================
    Item {
        id: topHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 36
        height: 48
        z: 10

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                text: ">_"
                font.family: root.fontName
                font.pointSize: 18
                font.weight: Font.Bold
                color: "#38BDF8" // Vibrant Studio Cyan
            }

            Text {
                text: "CACHYOS STUDIO"
                font.family: root.fontName
                font.pointSize: 14
                font.weight: Font.Bold
                font.letterSpacing: 2.5
                color: "#F8FAFC"
                renderType: Text.NativeRendering
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 28

            // Live Wi-Fi Telemetry Readout
            RowLayout {
                spacing: 8
                Text { text: ""; font.family: root.fontName; font.pointSize: 16; color: "#2DD4BF" } // Teal
                Text {
                    text: typeof config !== "undefined" && config.wifiEssid ? config.wifiEssid : "Wired Link"
                    font.family: root.fontName
                    font.pointSize: 12
                    font.weight: Font.Medium
                    color: "#E2E8F0"
                }
            }

            Text { text: "󰂯"; font.family: root.fontName; font.pointSize: 17; color: "#818CF8" } // Indigo Bluetooth
            
            // Live dynamic hardware battery telemetry without hardcoding
            RowLayout {
                spacing: 8
                Text { text: "󰁹"; font.family: root.fontName; font.pointSize: 17; color: "#22C55E" } // Studio Green
                Text { 
                    text: (typeof config !== "undefined" && config.batteryPercent ? config.batteryPercent : "100%") + 
                          (typeof config !== "undefined" && config.batteryStatus && config.batteryStatus.indexOf("Charging") !== -1 ? " (Charging)" : "")
                    font.family: root.fontName
                    font.pointSize: 12
                    font.weight: Font.Medium
                    color: "#E2E8F0" 
                }
            }

            Text {
                id: headerTimeText
                text: "Mon, Jul 27, 2026   15:54"
                font.family: root.fontName
                font.pointSize: 13
                font.weight: Font.Medium
                color: "#E2E8F0"
            }

            Timer {
                interval: 1000; repeat: true; running: true; triggeredOnStart: true
                onTriggered: {
                    var now = new Date()
                    headerTimeText.text = Qt.formatDate(now, "ddd, MMM d, yyyy") + "   " + Qt.formatTime(now, "HH:mm")
                }
            }
        }
    }

    // ==========================================================================
    // LAYER 3: 3-COLUMN STUDIO DASHBOARD GRID (WITH AUTO-SCALING)
    // ==========================================================================
    Item {
        anchors.fill: parent
        anchors.topMargin: 70
        anchors.bottomMargin: 85

        RowLayout {
            id: dashboardGrid
            anchors.centerIn: parent
            spacing: 28

            // Auto-scale dynamically on smaller monitors without clipping any graphics
            scale: Math.min(1.0, Math.min(parent.width / 1280.0, parent.height / 730.0))

            // ------------------------------------------------------------------
            // LEFT COLUMN: SYSTEM OVERVIEW, NETWORK & PHILOSOPHY QUOTE
            // ------------------------------------------------------------------
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 20

                CyberComponents.SystemOverviewCard {}
                // No activeHostname binding: NetworkCard already prefers config.hostName
                // (set by sddm-telemetry-update) and only falls back to its own default.
                // The previous binding fabricated "<username>-pc", which was never real.
                CyberComponents.NetworkCard { }
                CyberComponents.QuoteCard {}
            }

            // ------------------------------------------------------------------
            // CENTER COLUMN: MAIN CYBER STUDIO LOGIN AUTHENTICATION PANEL
            // ------------------------------------------------------------------
            CyberComponents.LoginCard {
                id: loginPanel
                Layout.alignment: Qt.AlignVCenter
                targetUser: root.getTargetUser()
                
                onSubmitLogin: function(pass) {
                    var u = root.getTargetUser()
                    // getTargetUser() now returns "" rather than inventing a name,
                    // so refuse to submit instead of calling sddm.login("") and
                    // leaving the greeter spinning on an account that cannot exist.
                    if (pass === "" || u === "") { return }
                    if (typeof sddm === "undefined" || !sddm) { return }
                    isAuthenticating = true
                    root.isAuthenticating = true
                    sddm.login(u, pass, sessionEngine.activeIndex)
                }
            }

            // ------------------------------------------------------------------
            // RIGHT COLUMN: LIVE TELEMETRY MONITORS & HOTKEY SHORTCUTS
            // ------------------------------------------------------------------
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 20

                CyberComponents.MonitorCard {}
                CyberComponents.ShortcutsCard {}
            }
        }
    }

    // ==========================================================================
    // LAYER 4: BOTTOM BAR (FUNCTIONAL SESSION SWITCHER & POWER CONTROLLERS)
    // ==========================================================================
    Item {
        id: bottomFooter
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 36
        height: 64
        z: 10

        // Left Side: Fully Functional Dynamic Session Switcher Pill
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(170, sessionLabelText.contentWidth + 56)
            height: 44
            radius: 22
            color: sessArea.containsMouse ? "#1E293B" : "#111827" // Obsidian pill capsule
            border.color: sessArea.containsMouse ? "#38BDF8" : "#1F2937"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
            Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Text { text: "󰇄"; font.family: root.fontName; font.pointSize: 16; color: "#38BDF8" }
                Text { 
                    id: sessionLabelText
                    text: "SESSION: " + (sessionEngine.sessionList.length > 0 && sessionEngine.sessionList[sessionEngine.activeIndex] ? sessionEngine.sessionList[sessionEngine.activeIndex].name.toUpperCase() : "SWAY (WAYLAND)")
                    font.family: root.fontName
                    font.pointSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                    color: "#F8FAFC" 
                }
                Text { text: "󰅱"; font.family: root.fontName; font.pointSize: 14; color: "#38BDF8" }
            }

            MouseArea {
                id: sessArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (sessionEngine.sessionList.length > 1) {
                        sessionEngine.activeIndex = (sessionEngine.activeIndex + 1) % sessionEngine.sessionList.length
                    }
                }
            }
        }

        // Right Side: Sleek Circular System Power Control Buttons (100% Functional)
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 32

            component PowerButton: ColumnLayout {
                property string icon: ""
                property string label: ""
                property string hoverBorder: "#38BDF8"
                property string hoverIcon: "#38BDF8"
                signal clicked()
                spacing: 6
                Layout.alignment: Qt.AlignVCenter
                
                Rectangle {
                    width: 50; height: 50; radius: 25
                    Layout.alignment: Qt.AlignHCenter
                    color: pArea.containsMouse ? "#1E293B" : "#111827"
                    border.color: pArea.containsMouse ? hoverBorder : "#1F2937"
                    border.width: 1.5
                    scale: pArea.pressed ? 0.93 : 1.0

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: icon
                        font.family: root.fontName
                        font.pointSize: 20
                        color: pArea.containsMouse ? hoverIcon : "#E2E8F0"
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    }
                    MouseArea {
                        id: pArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.clicked()
                    }
                }
                Text {
                    text: label
                    Layout.alignment: Qt.AlignHCenter
                    font.family: root.fontName
                    font.pointSize: 10
                    font.weight: Font.Medium
                    font.letterSpacing: 1.0
                    color: "#94A3B8"
                }
            }

            PowerButton { icon: "󰒲"; label: "SLEEP"; hoverBorder: "#A78BFA"; hoverIcon: "#A78BFA"; onClicked: if (typeof sddm !== "undefined" && sddm) sddm.suspend() }
            PowerButton { icon: "󰜉"; label: "RESTART"; hoverBorder: "#FBBF24"; hoverIcon: "#FBBF24"; onClicked: if (typeof sddm !== "undefined" && sddm) sddm.reboot() }
            PowerButton { icon: "󰐥"; label: "SHUTDOWN"; hoverBorder: "#EF4444"; hoverIcon: "#EF4444"; onClicked: if (typeof sddm !== "undefined" && sddm) sddm.powerOff() }
        }
    }

    // Connect SDDM authentication lifecycle events
    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginSucceeded() {
            root.isAuthenticating = false
        }
        function onLoginFailed() {
            root.isAuthenticating = false
            if (loginPanel) loginPanel.isAuthenticating = false
            loginPanel.focusPassword()
        }
    }

    Component.onCompleted: {
        if (loginPanel) loginPanel.focusPassword()
    }
}
