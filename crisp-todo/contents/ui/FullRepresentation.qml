import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: full

    property var store
    property string filter: "all"       // all | active | done
    property bool newImportant: false

    readonly property color tc: PlasmaCore.Theme.textColor
    readonly property color hl: PlasmaCore.Theme.highlightColor
    readonly property int visibleCount: !store ? 0
                                       : filter === "active" ? store.remainingCount
                                       : filter === "done"   ? store.doneCount
                                       :                       store.totalCount

    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 16
    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 18
    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 22
    Layout.preferredHeight: PlasmaCore.Units.gridUnit * 28

    function submit() {
        if (store.addTask(input.text, newImportant)) {
            input.text = ""
            newImportant = false
            if (filter === "done")
                filter = "all"
        }
    }

    Connections {
        target: plasmoid
        function onExpandedChanged() {
            if (plasmoid.expanded)
                input.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: PlasmaCore.Units.smallSpacing
        spacing: PlasmaCore.Units.largeSpacing

        // ---- Header --------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.6
                    font.weight: Font.DemiBold
                    text: plasmoid.configuration.title || i18n("My Tasks")
                    elide: Text.ElideRight
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    opacity: 0.7
                    elide: Text.ElideRight
                    text: {
                        if (!store || store.totalCount === 0)
                            return i18n("Nothing planned yet")
                        if (store.remainingCount === 0)
                            return i18n("Everything is done. Nice work!")
                        return i18n("%1 of %2 done", store.doneCount, store.totalCount)
                    }
                }
            }

            ProgressRing {
                visible: store && store.totalCount > 0
                value: store && store.totalCount > 0 ? store.doneCount / store.totalCount : 0
            }
        }

        // ---- Input -----------------------------------------------------------
        Rectangle {
            id: inputBox
            Layout.fillWidth: true
            implicitHeight: Math.max(Math.round(PlasmaCore.Units.gridUnit * 2.3), input.implicitHeight)
            radius: height / 2
            color: Qt.rgba(full.tc.r, full.tc.g, full.tc.b, 0.05)
            border.width: input.activeFocus ? 2 : 1
            border.color: input.activeFocus ? full.hl : Qt.rgba(full.tc.r, full.tc.g, full.tc.b, 0.15)
            Behavior on border.color { ColorAnimation { duration: PlasmaCore.Units.shortDuration } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: PlasmaCore.Units.smallSpacing * 1.5
                anchors.rightMargin: PlasmaCore.Units.smallSpacing
                spacing: PlasmaCore.Units.smallSpacing

                // Round "+" button
                Rectangle {
                    id: addButton
                    readonly property bool canAdd: input.text.trim().length > 0
                    Layout.preferredWidth: Math.round(PlasmaCore.Units.gridUnit * 1.4)
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: canAdd ? full.hl : Qt.rgba(full.tc.r, full.tc.g, full.tc.b, 0.15)
                    scale: addMouse.pressed ? 0.88 : 1
                    Behavior on color { ColorAnimation { duration: PlasmaCore.Units.shortDuration } }
                    Behavior on scale { NumberAnimation { duration: PlasmaCore.Units.shortDuration } }

                    readonly property color fg: canAdd ? PlasmaCore.Theme.highlightedTextColor : full.tc
                    Rectangle { anchors.centerIn: parent; width: parent.width * 0.5; height: 2; radius: 1; color: addButton.fg }
                    Rectangle { anchors.centerIn: parent; width: 2; height: parent.height * 0.5; radius: 1; color: addButton.fg }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: full.submit()
                    }
                }

                PlasmaComponents3.TextField {
                    id: input
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: i18n("Add a task…")
                    background: Item {}
                    onAccepted: full.submit()
                    Keys.onEscapePressed: {
                        if (text.length > 0)
                            text = ""
                        else
                            plasmoid.expanded = false
                    }
                    Component.onCompleted: forceActiveFocus()
                }

                PlasmaComponents3.ToolButton {
                    Layout.alignment: Qt.AlignVCenter
                    icon.name: full.newImportant ? "rating" : "rating-unrated"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    text: i18n("Add as important")
                    checkable: true
                    checked: full.newImportant
                    onToggled: full.newImportant = checked
                    opacity: full.newImportant || hovered || input.text.length > 0 ? 1 : 0.4
                    PlasmaComponents3.ToolTip.text: text
                    PlasmaComponents3.ToolTip.visible: hovered
                    PlasmaComponents3.ToolTip.delay: PlasmaCore.Units.longDuration * 3
                }
            }
        }

        // ---- List ------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            PlasmaComponents3.ScrollView {
                id: scroll
                anchors.fill: parent
                PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

                ListView {
                    id: list
                    model: store ? store.model : null
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    reuseItems: false

                    delegate: TodoDelegate {
                        store: full.store
                        listView: list
                        filter: full.filter
                    }

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: PlasmaCore.Units.longDuration }
                        NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: PlasmaCore.Units.longDuration; easing.type: Easing.OutBack }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: PlasmaCore.Units.shortDuration }
                    }
                    move: Transition {
                        NumberAnimation { properties: "x,y"; duration: PlasmaCore.Units.longDuration; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: PlasmaCore.Units.longDuration; easing.type: Easing.OutCubic }
                        // make sure interrupted add-animations never leave items half transparent
                        NumberAnimation { property: "opacity"; to: 1; duration: PlasmaCore.Units.shortDuration }
                        NumberAnimation { property: "scale"; to: 1; duration: PlasmaCore.Units.shortDuration }
                    }
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - PlasmaCore.Units.gridUnit * 2
                visible: full.visibleCount === 0
                spacing: PlasmaCore.Units.largeSpacing

                readonly property bool allDone: store && store.totalCount > 0 && full.filter !== "done"

                CheckCircle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: PlasmaCore.Units.gridUnit * 3.5
                    checked: parent.allDone
                    enabled: false
                    opacity: parent.allDone ? 1 : 0.35
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.25
                    font.weight: Font.DemiBold
                    text: full.filter === "done" ? i18n("Nothing completed yet")
                        : parent.allDone ? i18n("All clear!")
                        : i18n("No tasks yet")
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    opacity: 0.6
                    text: full.filter === "done" ? i18n("Finished tasks will show up here.")
                        : parent.allDone ? i18n("You finished everything. Enjoy the free time.")
                        : i18n("Type above and press Enter to add your first task.")
                }
            }
        }

        // ---- Undo bar ----------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            visible: store && store.undoAvailable
            implicitHeight: undoRow.implicitHeight + PlasmaCore.Units.smallSpacing * 2
            radius: PlasmaCore.Units.smallSpacing * 2
            color: Qt.rgba(full.hl.r, full.hl.g, full.hl.b, 0.15)

            RowLayout {
                id: undoRow
                anchors.fill: parent
                anchors.leftMargin: PlasmaCore.Units.largeSpacing
                anchors.rightMargin: PlasmaCore.Units.smallSpacing
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: store ? store.undoText : ""
                    elide: Text.ElideRight
                }
                PlasmaComponents3.ToolButton {
                    icon.name: "edit-undo"
                    text: i18n("Undo")
                    onClicked: store.undo()
                }
            }
        }

        // ---- Footer: filters ------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            visible: store && store.totalCount > 0
            spacing: PlasmaCore.Units.smallSpacing

            Rectangle {
                implicitWidth: tabs.implicitWidth + 4
                implicitHeight: tabs.implicitHeight + 4
                radius: height / 2
                color: Qt.rgba(full.tc.r, full.tc.g, full.tc.b, 0.06)

                Row {
                    id: tabs
                    anchors.centerIn: parent
                    spacing: 0

                    Repeater {
                        model: [
                            { key: "all",    label: i18n("All"),    count: store ? store.totalCount : 0 },
                            { key: "active", label: i18n("Active"), count: store ? store.remainingCount : 0 },
                            { key: "done",   label: i18n("Done"),   count: store ? store.doneCount : 0 }
                        ]
                        delegate: Rectangle {
                            readonly property bool selected: full.filter === modelData.key
                            implicitWidth: tabLabel.implicitWidth + PlasmaCore.Units.gridUnit
                            implicitHeight: tabLabel.implicitHeight + PlasmaCore.Units.smallSpacing * 2
                            width: implicitWidth
                            height: implicitHeight
                            radius: height / 2
                            color: selected ? full.hl
                                 : tabMouse.containsMouse ? Qt.rgba(full.tc.r, full.tc.g, full.tc.b, 0.08)
                                 : "transparent"
                            Behavior on color { ColorAnimation { duration: PlasmaCore.Units.shortDuration } }

                            PlasmaComponents3.Label {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.label + "  " + modelData.count
                                color: parent.selected ? PlasmaCore.Theme.highlightedTextColor : PlasmaCore.Theme.textColor
                                font.weight: parent.selected ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: full.filter = modelData.key
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents3.ToolButton {
                visible: store && store.doneCount > 0
                icon.name: "edit-clear-all"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: i18n("Clear completed tasks")
                onClicked: store.clearDone()
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: PlasmaCore.Units.longDuration * 3
            }
        }
    }
}
