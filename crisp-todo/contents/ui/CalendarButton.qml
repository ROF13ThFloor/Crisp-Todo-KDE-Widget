import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

// Round button with the drawn calendar icon and an optional text label.
Rectangle {
    id: button

    property string label: ""
    property string toolTip: ""
    property color iconColor: PlasmaCore.Theme.textColor
    signal clicked()

    readonly property color tc: PlasmaCore.Theme.textColor

    implicitHeight: Math.round(PlasmaCore.Units.gridUnit * 1.5)
    implicitWidth: label ? contentRow.implicitWidth + PlasmaCore.Units.smallSpacing * 3 : implicitHeight
    radius: height / 2
    color: mouse.pressed ? Qt.rgba(tc.r, tc.g, tc.b, 0.2)
         : mouse.containsMouse ? Qt.rgba(tc.r, tc.g, tc.b, 0.1)
         : "transparent"
    Behavior on color { ColorAnimation { duration: PlasmaCore.Units.shortDuration } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: PlasmaCore.Units.smallSpacing

        CalendarIcon {
            anchors.verticalCenter: parent.verticalCenter
            color: button.iconColor
        }
        PlasmaComponents3.Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: button.label !== ""
            text: button.label
            color: button.iconColor
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }

    PlasmaComponents3.ToolTip.text: toolTip
    PlasmaComponents3.ToolTip.visible: mouse.containsMouse && toolTip !== ""
    PlasmaComponents3.ToolTip.delay: PlasmaCore.Units.longDuration * 3
}
