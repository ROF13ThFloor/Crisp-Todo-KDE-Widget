import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: root

    // ---- public state used by the representations -------------------------
    readonly property alias model: todoModel
    property int totalCount: 0
    property int doneCount: 0
    readonly property int remainingCount: totalCount - doneCount

    property var undoEntries: []
    property string undoText: ""
    readonly property bool undoAvailable: undoEntries.length > 0

    // ---- plasmoid setup ---------------------------------------------------
    Plasmoid.icon: "view-task"
    Plasmoid.toolTipMainText: plasmoid.configuration.title || i18n("My Tasks")
    Plasmoid.toolTipSubText: {
        if (totalCount === 0)
            return i18n("No tasks yet")
        if (remainingCount === 0)
            return i18n("All done!")
        return i18np("%1 task left", "%1 tasks left", remainingCount)
    }
    Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 12
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 14

    Plasmoid.compactRepresentation: CompactRepresentation { store: root }
    Plasmoid.fullRepresentation: FullRepresentation { store: root }

    ListModel { id: todoModel }

    Timer {
        id: sinkTimer
        interval: 650
        onTriggered: root.sinkDone()
    }

    Timer {
        id: undoTimer
        interval: 6000
        onTriggered: root.dropUndo()
    }

    Component.onCompleted: load()

    // ---- helpers ----------------------------------------------------------
    function copyItem(i) {
        var t = todoModel.get(i)
        return { text: t.text, done: t.done, important: t.important }
    }

    function recount() {
        var done = 0
        for (var i = 0; i < todoModel.count; i++) {
            if (todoModel.get(i).done)
                done++
        }
        totalCount = todoModel.count
        doneCount = done
    }

    function load() {
        todoModel.clear()
        var arr = []
        try {
            arr = JSON.parse(plasmoid.configuration.todos || "[]")
        } catch (e) {
            console.warn("Crisp Todo: could not parse stored tasks:", e)
            arr = []
        }
        for (var i = 0; i < arr.length; i++) {
            var t = arr[i] || {}
            todoModel.append({
                text: String(t.text || ""),
                done: !!t.done,
                important: !!t.important
            })
        }
        recount()
    }

    function save() {
        var arr = []
        for (var i = 0; i < todoModel.count; i++)
            arr.push(copyItem(i))
        plasmoid.configuration.todos = JSON.stringify(arr)
        recount()
    }

    function firstDoneIndex() {
        for (var i = 0; i < todoModel.count; i++) {
            if (todoModel.get(i).done)
                return i
        }
        return todoModel.count
    }

    // ---- actions ----------------------------------------------------------
    function addTask(text, important) {
        text = (text || "").trim()
        if (text.length === 0)
            return false
        var pos
        if (plasmoid.configuration.newOnTop)
            pos = 0
        else if (plasmoid.configuration.sinkCompleted)
            pos = firstDoneIndex()
        else
            pos = todoModel.count
        todoModel.insert(pos, { text: text, done: false, important: !!important })
        save()
        return true
    }

    function toggleDone(i) {
        if (i < 0 || i >= todoModel.count)
            return
        todoModel.setProperty(i, "done", !todoModel.get(i).done)
        save()
        if (plasmoid.configuration.sinkCompleted)
            sinkTimer.restart()
    }

    function toggleImportant(i) {
        if (i < 0 || i >= todoModel.count)
            return
        todoModel.setProperty(i, "important", !todoModel.get(i).important)
        save()
    }

    function setText(i, text) {
        if (i < 0 || i >= todoModel.count)
            return
        text = (text || "").trim()
        if (text.length === 0) {
            remove(i)
            return
        }
        if (text !== todoModel.get(i).text) {
            todoModel.setProperty(i, "text", text)
            save()
        }
    }

    function remove(i) {
        if (i < 0 || i >= todoModel.count)
            return
        var entry = { index: i, item: copyItem(i) }
        todoModel.remove(i)
        offerUndo([entry], i18n("Task deleted"))
        save()
    }

    function clearDone() {
        var entries = []
        for (var i = todoModel.count - 1; i >= 0; i--) {
            if (todoModel.get(i).done) {
                entries.unshift({ index: i, item: copyItem(i) })
                todoModel.remove(i)
            }
        }
        if (entries.length > 0) {
            offerUndo(entries, i18np("Cleared %1 completed task", "Cleared %1 completed tasks", entries.length))
            save()
        }
    }

    function move(from, to) {
        if (from === to || from < 0 || to < 0 || from >= todoModel.count || to >= todoModel.count)
            return
        todoModel.move(from, to, 1)
    }

    // Stable partition: unfinished tasks first, finished ones after, each
    // group keeping its relative order.
    function sinkDone() {
        var target = todoModel.count - 1
        for (var i = todoModel.count - 1; i >= 0; i--) {
            if (todoModel.get(i).done) {
                if (i !== target)
                    todoModel.move(i, target, 1)
                target--
            }
        }
        save()
    }

    // ---- undo -------------------------------------------------------------
    function offerUndo(entries, text) {
        undoEntries = entries
        undoText = text
        undoTimer.restart()
    }

    function dropUndo() {
        undoTimer.stop()
        undoEntries = []
    }

    function undo() {
        var entries = undoEntries
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i]
            todoModel.insert(Math.min(e.index, todoModel.count), e.item)
        }
        dropUndo()
        save()
    }
}
