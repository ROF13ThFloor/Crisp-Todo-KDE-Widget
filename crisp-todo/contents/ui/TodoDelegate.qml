import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: row

    property var store
    property ListView listView
    property string filter: "all"

    // Asks the list to open the date picker for this task.
    signal dueRequested(int taskIndex)

    readonly property bool shown: filter === "all"
                                  || (filter === "active" && !model.done)
                                  || (filter === "done" && model.done)
                                  || (filter === "today" && !model.done && model.due !== ""
                                      && store && model.due <= store.today)
    readonly property bool dragging: handleArea.pressed
    readonly property bool hovered: hover.hovered || dragging
    property bool editing: false

    readonly property color tc: PlasmaCore.Theme.textColor
    readonly property color hl: PlasmaCore.Theme.highlightColor
    readonly property color starColor: PlasmaCore.Theme.neutralTextColor

    width: listView ? listView.width : 0
    height: shown ? card.height + PlasmaCore.Units.smallSpacing : 0
    visible: shown
    z: dragging ? 10 : 1

    function startEdit() {
        editField.text = model.text
        editing = true
        editField.forceActiveFocus()
        editField.selectAll()
    }
    function commitEdit() {
        if (!editing)
            return
        editing = false
        store.setText(index, editField.text)
    }
    function cancelEdit() {
        editing = false
    }

    Rectangle {
        id: card
        width: parent.width
        height: Math.max(content.implicitHeight + PlasmaCore.Units.smallSpacing * 3,
                         Math.round(PlasmaCore.Units.gridUnit * 2.3))
        radius: PlasmaCore.Units.smallSpacing * 2
        color: row.dragging ? Qt.rgba(row.hl.r, row.hl.g, row.hl.b, 0.18)
             : row.hovered  ? Qt.rgba(row.tc.r, row.tc.g, row.tc.b, 0.08)
             :                Qt.rgba(row.tc.r, row.tc.g, row.tc.b, 0.04)
        border.width: row.dragging || row.editing ? 1 : 0
        border.color: row.hl
        Behavior on color { ColorAnimation { duration: PlasmaCore.Units.shortDuration } }

        HoverHandler { id: hover }

        // Accent stripe for important tasks
        Rectangle {
            width: 3
            radius: 1.5
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: PlasmaCore.Units.smallSpacing * 1.5
                bottomMargin: PlasmaCore.Units.smallSpacing * 1.5
            }
            color: row.starColor
            opacity: model.important ? (model.done ? 0.4 : 1) : 0
            Behavior on opacity { NumberAnimation { duration: PlasmaCore.Units.shortDuration } }
        }

        RowLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: PlasmaCore.Units.smallSpacing
                rightMargin: PlasmaCore.Units.smallSpacing
            }
            spacing: PlasmaCore.Units.smallSpacing * 1.5

            // Drag handle
            Item {
                Layout.preferredWidth: Math.round(PlasmaCore.Units.gridUnit * 0.6)
                Layout.preferredHeight: PlasmaCore.Units.gridUnit * 1.4
                Layout.alignment: Qt.AlignVCenter
                opacity: (row.hovered && row.filter === "all" && !row.editing) ? 0.55 : 0
                Behavior on opacity { NumberAnimation { duration: PlasmaCore.Units.shortDuration } }

                Grid {
                    anchors.centerIn: parent
                    columns: 2
                    spacing: 2
                    Repeater {
                        model: 6
                        Rectangle { width: 3; height: 3; radius: 1.5; color: row.tc }
                    }
                }

                MouseArea {
                    id: handleArea
                    anchors.fill: parent
                    anchors.margins: -2
                    enabled: row.filter === "all" && !row.editing
                    preventStealing: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onPositionChanged: {
                        if (!pressed || !row.listView)
                            return
                        var p = mapToItem(row.listView.contentItem, mouse.x, mouse.y)
                        var to = row.listView.indexAt(row.listView.width / 2, p.y)
                        if (to >= 0 && to !== index)
                            row.store.move(index, to)
                    }
                    onReleased: row.store.save()
                }
            }

            CheckCircle {
                Layout.alignment: Qt.AlignVCenter
                checked: model.done
                onToggled: row.store.toggleDone(index)
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Math.round(PlasmaCore.Units.smallSpacing * 0.75)

                Item {
                    Layout.fillWidth: true
                    implicitHeight: row.editing ? editField.implicitHeight : label.implicitHeight

                    PlasmaComponents3.Label {
                        id: label
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !row.editing
                        text: model.text
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        font.strikeout: model.done
                        opacity: model.done ? 0.5 : 1
                        Behavior on opacity { NumberAnimation { duration: PlasmaCore.Units.longDuration } }

                        MouseArea {
                            anchors.fill: parent
                            onDoubleClicked: row.startEdit()
                        }
                    }

                    PlasmaComponents3.TextField {
                        id: editField
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.editing
                        onAccepted: row.commitEdit()
                        onActiveFocusChanged: if (!activeFocus && row.editing) row.commitEdit()
                        Keys.onEscapePressed: row.cancelEdit()
                    }
                }

                // Due date chip
                Rectangle {
                    id: dueChip
                    readonly property int days: model.due ? row.store.daysUntil(model.due) : 0
                    readonly property bool overdue: model.due !== "" && days < 0 && !model.done
                    readonly property bool dueToday: model.due !== "" && days === 0 && !model.done
                    readonly property color fg: overdue ? PlasmaCore.Theme.negativeTextColor
                                              : dueToday ? row.hl
                                              : row.tc

                    visible: model.due !== "" && !row.editing
                    Layout.alignment: Qt.AlignLeft
                    implicitWidth: chipLabel.implicitWidth + PlasmaCore.Units.smallSpacing * 3
                    implicitHeight: chipLabel.implicitHeight + 2
                    radius: height / 2
                    color: Qt.rgba(fg.r, fg.g, fg.b, chipMouse.containsMouse ? 0.24 : 0.13)
                    opacity: model.done ? 0.5 : 1

                    PlasmaComponents3.Label {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: row.store ? row.store.dueLabel(model.due) : ""
                        color: dueChip.fg
                        font: PlasmaCore.Theme.smallestFont
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.dueRequested(index)
                    }
                    PlasmaComponents3.ToolTip.text: model.due
                        ? (dueChip.overdue ? i18n("Overdue: %1", Qt.formatDate(row.store.parseDate(model.due), Qt.DefaultLocaleLongDate))
                                           : i18n("Due %1", Qt.formatDate(row.store.parseDate(model.due), Qt.DefaultLocaleLongDate)))
                        : ""
                    PlasmaComponents3.ToolTip.visible: chipMouse.containsMouse
                    PlasmaComponents3.ToolTip.delay: PlasmaCore.Units.longDuration * 3
                }
            }

            // Star stays visible for important tasks (hover actions cover it otherwise)
            PlasmaComponents3.ToolButton {
                Layout.alignment: Qt.AlignVCenter
                visible: model.important && !row.editing
                icon.name: "rating"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: i18n("Unmark as important")
                onClicked: row.store.toggleImportant(index)
            }
        }

        // Hover actions, floating over the end of the row so the task text
        // can use the full width when the mouse is elsewhere.
        Item {
            id: actions
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: actionRow.implicitWidth + PlasmaCore.Units.gridUnit + PlasmaCore.Units.smallSpacing
            visible: opacity > 0
            opacity: row.hovered && !row.editing && !row.dragging ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: PlasmaCore.Units.shortDuration } }

            readonly property real fade: PlasmaCore.Units.gridUnit / width

            // Same color as the card, but opaque, with a soft fade on the left.
            Rectangle {
                anchors.fill: parent
                radius: card.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: actions.fade; color: PlasmaCore.Theme.backgroundColor }
                    GradientStop { position: 1; color: PlasmaCore.Theme.backgroundColor }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: card.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: actions.fade; color: card.color }
                    GradientStop { position: 1; color: card.color }
                }
            }

            Row {
                id: actionRow
                anchors.right: parent.right
                anchors.rightMargin: PlasmaCore.Units.smallSpacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                CalendarButton {
                    anchors.verticalCenter: parent.verticalCenter
                    toolTip: model.due ? i18n("Change due date") : i18n("Set due date")
                    onClicked: row.dueRequested(index)
                }

                PlasmaComponents3.ToolButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon.name: model.important ? "rating" : "rating-unrated"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    text: model.important ? i18n("Unmark as important") : i18n("Mark as important")
                    onClicked: row.store.toggleImportant(index)
                    PlasmaComponents3.ToolTip.text: text
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: PlasmaCore.Units.longDuration * 3
                }

                PlasmaComponents3.ToolButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon.name: "edit-delete"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    text: i18n("Delete")
                    onClicked: row.store.remove(index)
                    PlasmaComponents3.ToolTip.text: text
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: PlasmaCore.Units.longDuration * 3
                }
            }
        }
    }
}
