import QtQuick 2.15
import QtQuick.Layouts 1.15

/*
 * Split Cyan & White Studio Clock Module for SDDM
 * Features dual-colored hours/minutes typography replicating the modular Cyber Studio Waybar.
 */
ColumnLayout {
    id: clockContainer
    spacing: 6

    property string fontName: "JetBrainsMono Nerd Font"
    property string colorHour: "#F8FAFC"
    property string colorMinute: "#38BDF8"
    property string colorDate: "#94A3B8"
    property int clockSize: 64
    property int dateSize: 14

    // Precision internal second timer
    Timer {
        id: timeTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var currentDate = new Date()
            hourText.text = Qt.formatTime(currentDate, "HH")
            minuteText.text = Qt.formatTime(currentDate, "mm")
            dateText.text = Qt.formatDate(currentDate, "dddd, MMMM d, yyyy").toUpperCase()
        }
    }

    // Split dual-color clock readout
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        Text {
            id: hourText
            text: "15"
            font.family: clockContainer.fontName
            font.pointSize: clockContainer.clockSize
            font.weight: Font.Bold
            color: clockContainer.colorHour
            renderType: Text.NativeRendering
        }

        Text {
            text: ":"
            font.family: clockContainer.fontName
            font.pointSize: clockContainer.clockSize
            font.weight: Font.Bold
            color: clockContainer.colorHour
            renderType: Text.NativeRendering
        }

        Text {
            id: minuteText
            text: "54"
            font.family: clockContainer.fontName
            font.pointSize: clockContainer.clockSize
            font.weight: Font.Bold
            color: clockContainer.colorMinute
            renderType: Text.NativeRendering
        }
    }

    // Secondary Cyber Date Display
    Text {
        id: dateText
        Layout.alignment: Qt.AlignHCenter
        text: "MONDAY, JULY 27, 2026"
        font.family: clockContainer.fontName
        font.pointSize: clockContainer.dateSize
        font.weight: Font.Medium
        font.letterSpacing: 2.2
        color: clockContainer.colorDate
        renderType: Text.NativeRendering
        opacity: 0.85
    }
}
