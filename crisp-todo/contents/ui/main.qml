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
    property int dueTodayCount: 0       // unfinished tasks due today or earlier
    property int overdueCount: 0        // unfinished tasks due before today

    // Today's date as "YYYY-MM-DD". Bindings that depend on it (due chips,
    // the Today filter) refresh automatically when the day changes.
    property string today: isoDate(new Date())

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
        var text = i18np("%1 task left", "%1 tasks left", remainingCount)
        if (overdueCount > 0)
            text += "\n" + i18np("%1 overdue", "%1 overdue", overdueCount)
        else if (dueTodayCount > 0)
            text += "\n" + i18np("%1 due today", "%1 due today", dueTodayCount)
        return text
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

    // Notice when the date changes (midnight, or waking from suspend).
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: {
            var now = root.isoDate(new Date())
            if (now !== root.today) {
                root.today = now
                root.recount()
            }
        }
    }

    Component.onCompleted: load()

    // ---- dates --------------------------------------------------------------
    function pad2(n) {
        return n < 10 ? "0" + n : "" + n
    }

    function isoDate(d) {
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
    }

    function isValidIsoDate(s) {
        return typeof s === "string" && /^\d{4}-\d{2}-\d{2}$/.test(s)
    }

    // "YYYY-MM-DD" -> local Date at midnight
    function parseDate(s) {
        var p = s.split("-")
        return new Date(parseInt(p[0], 10), parseInt(p[1], 10) - 1, parseInt(p[2], 10))
    }

    // Whole days from today until the given date (negative = in the past).
    function daysUntil(due) {
        if (!due)
            return 0
        return Math.round((parseDate(due) - parseDate(today)) / 86400000)
    }

    // Short, friendly label for a due date chip.
    function dueLabel(due) {
        if (!due)
            return ""
        var n = daysUntil(due)
        var d = parseDate(due)
        if (n === 0)
            return i18n("Today")
        if (n === 1)
            return i18n("Tomorrow")
        if (n === -1)
            return i18n("Yesterday")
        if (n > 1 && n < 7)
            return Qt.formatDate(d, "ddd d")
        if (d.getFullYear() === parseDate(today).getFullYear())
            return Qt.formatDate(d, "d MMM")
        return Qt.formatDate(d, "d MMM yyyy")
    }

    // ---- helpers ----------------------------------------------------------
    function copyItem(i) {
        var t = todoModel.get(i)
        return { text: t.text, done: t.done, important: t.important, due: t.due }
    }

    function recount() {
        var done = 0, dueToday = 0, overdue = 0
        for (var i = 0; i < todoModel.count; i++) {
            var t = todoModel.get(i)
            if (t.done) {
                done++
            } else if (t.due) {
                if (t.due <= today)
                    dueToday++
                if (t.due < today)
                    overdue++
            }
        }
        totalCount = todoModel.count
        doneCount = done
        dueTodayCount = dueToday
        overdueCount = overdue
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
                important: !!t.important,
                due: isValidIsoDate(t.due) ? t.due : ""
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
    function addTask(text, important, due) {
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
        todoModel.insert(pos, {
            text: text,
            done: false,
            important: !!important,
            due: isValidIsoDate(due) ? due : ""
        })
        save()
        return true
    }

    // due: "YYYY-MM-DD", or "" to remove the date
    function setDue(i, due) {
        if (i < 0 || i >= todoModel.count)
            return
        due = isValidIsoDate(due) ? due : ""
        if (due !== todoModel.get(i).due) {
            todoModel.setProperty(i, "due", due)
            save()
        }
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
