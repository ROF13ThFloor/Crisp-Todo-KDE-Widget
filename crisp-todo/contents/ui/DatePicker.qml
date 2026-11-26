import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

// Small date picker: quick choices on top, a month calendar below.
// Emits picked("YYYY-MM-DD"), or picked("") to remove the date.
QQC2.Popup {
    id: picker

    property var store
    property string selected: ""
    property int viewYear: 2000
    property int viewMonth: 0       // 0 = January

    signal picked(string date)

    readonly property color tc: PlasmaCore.Theme.textColor
    readonly property color hl: PlasmaCore.Theme.highlightColor
    readonly property int cell: Math.round(PlasmaCore.Units.gridUnit * 1.7)

    modal: true
    focus: true
    padding: PlasmaCore.Units.largeSpacing
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

    QQC2.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.25)
    }

    background: Rectangle {
        color: PlasmaCore.Theme.backgroundColor
        radius: PlasmaCore.Units.smallSpacing * 3
        border.width: 1
        border.color: Qt.rgba(picker.tc.r, picker.tc.g, picker.tc.b, 0.18)
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: PlasmaCore.Units.shortDuration }
        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: PlasmaCore.Units.shortDuration; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: PlasmaCore.Units.shortDuration }
    }

    function openFor(date) {
        selected = date || ""
        var d = store.parseDate(selected || store.today)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
        open()
    }

    function choose(date) {
        picked(date)
        close()
    }

    function shiftMonth(delta) {
        var d = new Date(viewYear, viewMonth + delta, 1)
        viewYear = d.getFullYear()
        viewMonth = d.getMonth()
    }

    function offsetDays(n) {
        var d = store.parseDate(store.today)
        d.setDate(d.getDate() + n)
        return store.isoDate(d)
    }

    function nextMonday() {
        var day = store.parseDate(store.today).getDay()   // 0 = Sunday
        return offsetDays((8 - day) % 7 || 7)
    }

    contentItem: ColumnLayout {
        spacing: PlasmaCore.Units.smallSpacing

        // ---- Quick choices ---------------------------------------------------
        Flow {
            Layout.preferredWidth: picker.cell * 7
            Layout.bottomMargin: PlasmaCore.Units.smallSpacing
            spacing: PlasmaCore.Units.smallSpacing

            Repeater {
                model: picker.store ? [
                    { label: i18n("Today"),     date: picker.store.today },
                    { label: i18n("Tomorrow"),  date: picker.offsetDays(1) },
                    { label: i18n("Next week"), date: picker.nextMonday() }
                ] : []

                delegate: Rectangle {
                    readonly property bool isSelected: modelData.date === picker.selected
                    implicitWidth: quickLabel.implicitWidth + PlasmaCore.Units.gridUnit
                    implicitHeight: quickLabel.implicitHeight + PlasmaCore.Units.smallSpacing * 2
                    radius: height / 2
                    color: isSelected ? picker.hl
                         : quickMouse.containsMouse ? Qt.rgba(picker.tc.r, picker.tc.g, picker.tc.b, 0.12)
                         : Qt.rgba(picker.tc.r, picker.tc.g, picker.tc.b, 0.06)

                    PlasmaComponents3.Label {
                        id: quickLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.isSelected ? PlasmaCore.Theme.highlightedTextColor : PlasmaCore.Theme.textColor
                    }
                    MouseArea {
                        id: quickMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: picker.choose(modelData.date)
                    }
                }
            }

            Rectangle {
                visible: picker.selected !== ""
                implicitWidth: clearLabel.implicitWidth + PlasmaCore.Units.gridUnit
                implicitHeight: clearLabel.implicitHeight + PlasmaCore.Units.smallSpacing * 2
                radius: height / 2
                readonly property color neg: PlasmaCore.Theme.negativeTextColor
                color: clearMouse.containsMouse ? Qt.rgba(neg.r, neg.g, neg.b, 0.18)
                                                : Qt.rgba(neg.r, neg.g, neg.b, 0.08)

                PlasmaComponents3.Label {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: i18n("No date")
                    color: parent.neg
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.choose("")
                }
            }
        }

        // ---- Month header ----------------------------------------------------
        RowLayout {
            Layout.preferredWidth: picker.cell * 7

            PlasmaComponents3.ToolButton {
                icon.name: "go-previous"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: i18n("Previous month")
                onClicked: picker.shiftMonth(-1)
            }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.weight: Font.DemiBold
                text: Qt.locale().standaloneMonthName(picker.viewMonth) + " " + picker.viewYear
            }
            PlasmaComponents3.ToolButton {
                icon.name: "go-next"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: i18n("Next month")
                onClicked: picker.shiftMonth(1)
            }
        }

        // ---- Weekday names ---------------------------------------------------
        Grid {
            columns: 7
            Repeater {
                model: 7
                PlasmaComponents3.Label {
                    width: picker.cell
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.6
                    font: PlasmaCore.Theme.smallestFont
                    text: Qt.locale().dayName((Qt.locale().firstDayOfWeek + index) % 7, Locale.ShortFormat)
                }
            }
        }

        // ---- Days ------------------------------------------------------------
        Grid {
            id: dayGrid
            columns: 7
            // How many cells of the previous month come before the 1st.
            readonly property int offset: (new Date(picker.viewYear, picker.viewMonth, 1).getDay()
                                           - Qt.locale().firstDayOfWeek + 7) % 7

            Repeater {
                model: 42
                delegate: Rectangle {
                    readonly property var date: new Date(picker.viewYear, picker.viewMonth, 1 - dayGrid.offset + index)
                    readonly property string iso: picker.store ? picker.store.isoDate(date) : ""
                    readonly property bool inMonth: date.getMonth() === picker.viewMonth
                    readonly property bool isSelected: iso === picker.selected
                    readonly property bool isToday: picker.store && iso === picker.store.today

                    width: picker.cell
                    height: picker.cell
                    radius: width / 2
                    color: isSelected ? picker.hl
                         : dayMouse.containsMouse ? Qt.rgba(picker.tc.r, picker.tc.g, picker.tc.b, 0.12)
                         : "transparent"
                    border.width: isToday && !isSelected ? 1 : 0
                    border.color: picker.hl

                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: parent.date.getDate()
                        color: parent.isSelected ? PlasmaCore.Theme.highlightedTextColor : PlasmaCore.Theme.textColor
                        opacity: parent.inMonth ? 1 : 0.35
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                    }
                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: picker.choose(parent.iso)
                    }
                }
            }
        }
    }
}
