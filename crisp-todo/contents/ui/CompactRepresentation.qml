import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

MouseArea {
    id: compact
    property var store

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: plasmoid.expanded = !plasmoid.expanded

    PlasmaCore.IconItem {
        id: icon
        anchors.fill: parent
        source: plasmoid.icon
        active: compact.containsMouse
    }

    Rectangle {
        id: badge
        visible: plasmoid.configuration.showBadge && compact.store && compact.store.remainingCount > 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(PlasmaCore.Units.gridUnit * 0.75, Math.round(compact.height * 0.45))
        width: Math.max(height, countLabel.implicitWidth + height * 0.5)
        radius: height / 2
        color: compact.store && compact.store.overdueCount > 0
               ? PlasmaCore.Theme.negativeTextColor
               : PlasmaCore.Theme.highlightColor
        border.width: 1
        border.color: PlasmaCore.Theme.backgroundColor

        PlasmaComponents3.Label {
            id: countLabel
            anchors.centerIn: parent
            text: compact.store ? (compact.store.remainingCount > 99 ? "99+" : compact.store.remainingCount) : ""
            color: PlasmaCore.Theme.highlightedTextColor
            font.pixelSize: Math.max(8, Math.round(badge.height * 0.68))
            font.bold: true
        }
    }
}
